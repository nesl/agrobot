clc
clear global;

obj = VideoReader('DJI_0011.MP4');
frame_lim = obj.NumFrames;
fprintf(sprintf('Number of frames = %d\n',frame_lim));
folder = obj.Name(1:end-4);
if exist(folder, 'dir')
    rmdir(folder,'s');
    mkdir(folder);
else
    mkdir(folder);
end
if isfile(strcat(folder,'.avi'))
    delete(strcat(folder,'.avi'))
end

fprintf(sprintf('Performing Pre-processing...\n'));
for i = 1:frame_lim
    disp(i);
    curFrame = rgb2gray(read(obj,i));
    noDarkObj = imextendedmax(curFrame, 10);
    noSmallStructures = imopen(noDarkObj, strel('disk',3));
    curFileName = strcat(folder,'_',string(i),'.png');
    imwrite(noSmallStructures,strcat(folder,"/",curFileName));
end

fprintf(sprintf('Performing Sequencing...\n'));
outputVideo = VideoWriter(folder);
outputVideo.FrameRate = obj.FrameRate;
open(outputVideo)
for ii = 1:frame_lim 
   curFileName = strcat(folder,'_',string(ii),'.png');
   img = imread(fullfile(folder,curFileName));
   writeVideo(outputVideo,im2double(img));
end
close(outputVideo);

rmdir(folder,'s');
clear global;
clc