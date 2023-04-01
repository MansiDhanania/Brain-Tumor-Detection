% Brain Tumour Detection using MRI Scans on MATLAB

% METHOD - 4D : MEDIAN FILTERING AND CANNY EDGE DETECTION

% Clear the work environment
close all;
clc;
close;

tic % start timer to see duration of code execution

% Import the image to be classified/sorted
[filename,pathname] = uigetfile({'*.*';'*.bmp';'*.tif';'*.gif';'*.png'},'Pick an Image File');
I = imread([pathname,filename]);
figure; subplot(2, 2, 1);
imshow(I); title('Brain MRI Image');
I = imresize(I,[400,400]);

% Convert to grayscale
gray = rgb2gray(I);

% Median Filter
M = medfilt2(gray);
subplot(2, 2, 2);
imshow(M); title('Median Filtered Image');

% Binarize and Threshold the filtered image
M1 = imbinarize(M, 'adaptive');

% Now extract tumour from the filtered image
% For Tumour Detection, we have to extract different parts of the image.
% Identify objects in the binary image
imagedata = bwconncomp(M1,4);
% Find the area of different regions.
braindata = regionprops(imagedata,'basic');
brainareas = [braindata.Area];
% Find and display the largest area object.
[max_area, idx] = max(brainareas);
brain = false(size(M1));
brain(imagedata.PixelIdxList{idx}) = true;
% subplot(2, 3, 3);
% imshow(brain); title("Part with largest area");

% Check the results and prompt to stop or continue detection.
prompt = sprintf('Do you wish to continue and find the tumor,\nor Quit?');
titleBarCaption = 'Continue?';
buttonText = questdlg(prompt, titleBarCaption, 'Continue', 'Quit', 'Continue');
if strcmpi(buttonText, 'Quit')
	return;
end

% Remove the largest part of the brain/skull
skullfreeimage = M1; % Initialize
skullfreeimage(brain) = 0; % Mask out.
subplot(2, 2, 3);
imshow(skullfreeimage, []); title("Removing the skull");

% Extract the next largest object, the tumor
tumor = bwareafilt(skullfreeimage, 1);

% Canny Edge Detection
CED = edge(tumor,'canny');
subplot(2, 2, 4);
imshow(CED); title('Canny Edge Detection');

toc % stop timer to see duration of code execution

% Area of the tumor identified
bwarea(CED)

% Histogram of original image
figure;
imhist(I); title('Image Data');