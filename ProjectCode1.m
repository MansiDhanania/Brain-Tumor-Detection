% Brain Tumour Detection using MRI Scans on MATLAB

% METHOD - 1 : SPLITTING REGIONS OF THE BRAIN MANUALLY

% Clear the work environment
close all;
clc;
close;

tic % start timer to see duration of code execution

% Import the image to be classified/sorted
[filename,pathname] = uigetfile({'*.*';'*.bmp';'*.tif';'*.gif';'*.png'},'Upload the MRI Scan: ');
I = imread([pathname,filename]);
figure; subplot(2, 3, 1);
imshow(I); title('Uploaded Brain MRI Image');
I = imresize(I,[400,400]);

% Convert to grayscale
gray = rgb2gray(I);

% Adaptive thresholding is the method where the threshold value is calculated 
% for smaller regions and therefore, there will be different threshold values for different regions.
% T = adaptthresh( I , sensitivity ) computes a locally adaptive threshold with sensitivity 
% factor specified by sensitivity . sensitivity is a scalar in the range [0,1] that 
% indicates sensitivity towards thresholding more pixels as foreground.
% By applying adaptive thresholding we can threshold local regions of the input 
% image (rather than using a global value of our threshold parameter, T). 
% Doing so dramatically improves our foreground and segmentation results.

% Binarize Grayscale Image Using Locally Adaptive Thresholding
B = imbinarize(gray, 'adaptive');
% Display original image along side binary version.
subplot(2, 3, 2);
imshow(gray); title('Gray-Scaled Image');
subplot(2, 3, 3);
imshow(B); title('Image after Adaptive Thresholding');

% For Tumour Detection, we have to extract different parts of the image.
% Identify objects in the binary image
imagedata = bwconncomp(B,4); % To count the connected components
% Find the area of different regions.
braindata = regionprops(imagedata,'basic');
brainareas = [braindata.Area];
% Find and display the largest area object.
[max_area, idx] = max(brainareas);
brain = false(size(B));
brain(imagedata.PixelIdxList{idx}) = true;
subplot(2, 3, 4);
imshow(brain); title("Part with largest area");

% % Check the results and prompt to stop or continue detection.
% prompt = sprintf('Do you wish to continue and find the tumor,\nor Quit?');
% titleBarCaption = 'Continue?';
% buttonText = questdlg(prompt, titleBarCaption, 'Continue', 'Quit', 'Continue');
% if strcmpi(buttonText, 'Quit')
% 	return;
% end

% Remove the largest part of the brain/skull
skullfreeimage = B; % Initialize
skullfreeimage(brain) = 0; % Mask out.
subplot(2, 3, 5);
imshow(skullfreeimage, []); title("Removing the skull");

% Extract the next largest object, the tumor
tumor = bwareafilt(skullfreeimage, 1);
subplot(2, 3, 6);
imshow(tumor, []); title("Detected Tumor");
hold on;
% Highlighting boundaries
boundaries = bwboundaries(tumor);
noofboundaries = size(boundaries, 1);
for k = 1 : noofboundaries
	thisBoundary = boundaries{k};
	plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
end
hold off;

toc % stop timer to see duration of code execution

% Area of the tumor identified
bwarea(tumor)

% Histogram of original image
figure;
imhist(I); title('Image Data');