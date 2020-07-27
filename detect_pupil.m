clc;
close all;
clear all;

mice_name = 'mice1';
video_name = [mice_name '.mp4'];
mkdir (mice_name)
mice = VideoReader(video_name);
numFrames = mice.NumberOfFrame;
first_frame = read(mice,1);
figure();imshow(first_frame);

h = imrect;
position = int16(getPosition(h));

Radius = [];

first_frame_gray = rgb2gray(first_frame);
ROI = first_frame_gray(position(2):position(2) + position(4),position(1):position(1) + position(3),:);
ROI_area = imfilter(ROI,ones(5)/25);


for i = 65:95
    ROI_threshold = ROI_area < i;
    figure();imshow(ROI_threshold);
    title(['Threshold = ' int2str(i)]);
end

prompt = 'What is the value?';
threshold = input(prompt);
close all;

for i = 1:numFrames
    first_frame = read(mice,i);
    first_frame_gray = rgb2gray(first_frame);
    ROI = first_frame_gray(position(2):position(2) + position(4),position(1):position(1) + position(3),:);

    ROI_area = imfilter(ROI,ones(5)/25);
    ROI_threshold = ROI_area < threshold;
    
   
    se = strel('disk',2);
    ROI_open = imopen(ROI_threshold,se);
    
    CC = bwconncomp(ROI_open);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [unused,indexOfMax] = max(numPixels);
    
    TF = isempty(indexOfMax);
    if TF == 1
        Radius = [Radius;0];
        continue;
    end
    ROI_open(:,:) = 0;
    ROI_open(CC.PixelIdxList{indexOfMax}) = 255;

    [x,y,r] = find_circle_center(ROI_open);

    RGB = insertShape(ROI,'circle',[x y r],'LineWidth',2);
    filename = [pwd '\' mice_name '\frame' int2str(i) '.jpg'];
    r = r*2;
    Radius = [Radius;r];
    imwrite(RGB,filename);
end


% M is the mean of the previous 10 diameter
M = movmean(Radius,10);
frame_rate = 30;
result_fig = figure();
set(result_fig,'position',[200 200 1300 800])
plot((1:length(M)),M,'.');
yticks([min(Radius):2:max(Radius)]);
saveas(result_fig,[mice_name '.png']);

%% write csv file
csvname = [mice_name '.csv'];
cHeader = {'frame' 'Radius' 'Moving Average'}; %dummy header
commaHeader = [cHeader;repmat({','},1,numel(cHeader))]; %insert commaas
commaHeader = commaHeader(:)';
textHeader = cell2mat(commaHeader); %cHeader in text with commas
% write header to file
fid = fopen(csvname,'w'); 
fprintf(fid,'%s\n',textHeader);
fclose(fid);
% write data to end of file
frame = 1:numFrames;
frame = frame';
csv = [frame Radius M];
dlmwrite(csvname,csv,'-append');






function [x,y,r] = find_circle_center(ROI)
    binaryImage = bwconvhull(ROI, 'object');
    props = regionprops(binaryImage, 'BoundingBox');
    
    x = int16(props.BoundingBox(1) + props.BoundingBox(3)/2);
    y = int16(props.BoundingBox(2) + props.BoundingBox(4)/2);
    r = int16(props.BoundingBox(4)/2);
end
