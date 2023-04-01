% Brain Tumour Detection using MRI Scans on MATLAB

% METHOD - 3 : K-MEANS CLUSTERING

% Clear the work environment
close all;
clc;
close;

tic

% Import the image to be classified/sorted
[filename,pathname] = uigetfile({'*.*';'*.bmp';'*.tif';'*.gif';'*.png'},'Upload the MRI Scan: ');
I = imread([pathname,filename]);
figure; subplot(3, 3, 1);
imshow(I); title('Uploaded Brain MRI Image');
I = imresize(I,[400,400]);

% Convert to grayscale
gray = rgb2gray(I);

% Binarize Grayscale Image Using Locally Adaptive Thresholding
B = imbinarize(gray, 'adaptive');
% Display original image along side binary version.
subplot(3, 3, 2);
imshow(gray); title('Grey-Scaled Image');
subplot(3, 3, 3);
imshow(B); title('Image after Adaptive Thresholding');

% Segment Image using K-Means Clustering into three parts
[L, centers] = imsegkmeans(I,3);
C = labeloverlay(I,L);
subplot(3, 3, 4);
imshow(C); title("Labeled Image after K-Means Clustering");

% To obtain the texture information, filter a grayscale version of the image with a set of Gabor filters.
% Improve the k-means segmentation by supplementing the information about each pixel
% Create a set of 24 Gabor filters, covering 6 wavelengths and 4 orientations
wavelength = 2.^(0:5) * 3;
orientation = 0:45:135;
g = gabor(wavelength,orientation);

% Filter the grayscale image using the Gabor filters. Display the 24 filtered images in a montage.
gabormag = imgaborfilt(gray,g);
% montage(gabormag,"Size",[4 6]);

% Smooth each filtered image to remove local variations. Display the smoothed images in a montage.
for i = 1:length(g)
    sigma = 0.5*g(i).Wavelength;
    % Using gaussian filter to smoothen the image
    gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),3*sigma); 
end
% figure;
% montage(gabormag,"Size",[4 6]); title("Smoothened Images");

% Get the x and y coordinates of all pixels in the input image.
nrows = size(I,1);
ncols = size(I,2);
[X,Y] = meshgrid(1:ncols,1:nrows);

% Concatenate the intensity information, neighborhood texture information, 
% and spatial information about each pixel.
featureSet = cat(3,gray,gabormag,X,Y);

% Segment the image into three regions using k-means clustering with the supplemented feature set.
[L2, centers2] = imsegkmeans(featureSet,3,"NormalizeInput",true);
C2 = labeloverlay(I,L2);
% subplot(2, 2, 4);
% imshow(C2); title("Labeled Image with Added Pixel Information");

% Check the results and prompt to stop or continue detection.
prompt = sprintf('Do you wish to continue and find the tumor,\nor Quit?');
titleBarCaption = 'Continue?';
buttonText = questdlg(prompt, titleBarCaption, 'Continue', 'Quit', 'Continue');
if strcmpi(buttonText, 'Quit')
	return;
end

% Convert the image to L*a*b* color space by using the rgb2lab function.
lab_I = rgb2lab(I);
% Classify Colors in a*b* Space Using K-Means Clustering
ab = lab_I(:,:,2:3);
ab = im2single(ab);
pixel_labels = imsegkmeans(ab,3,NumAttempts=3);

% Display label image as an overlay on the original image.
B2 = labeloverlay(I,pixel_labels);
% figure; subplot(2, 2, 1);
% imshow(B2); title("Labeled Image a*b*");

% Create Images that Segment Image by Color
mask1 = pixel_labels == 1;
cluster1 = I.*uint8(mask1);
subplot(3, 3, 5);
imshow(cluster1); title("Objects in Cluster 1");

mask2 = pixel_labels == 2;
cluster2 = I.*uint8(mask2);
subplot(3, 3, 6);
imshow(cluster2); title("Objects in Cluster 2");

mask3 = pixel_labels == 3;
cluster3 = I.*uint8(mask3);
subplot(3, 3, 7);
imshow(cluster3); title("Objects in Cluster 3");

% Segment Nuclei
L1 = lab_I(:,:,1);
L_white = L1.*double(mask3);
L_white = rescale(L_white);
whiteindex = imbinarize(nonzeros(L_white));

% Copy the mask of objects in mask3 and remove the white pixels from the mask. 
% Apply the new mask to the original image and display the result. 
% Only non-white pixels are visible.
white_idx = find(mask3);
mask_white = mask3;
mask_white(white_idx(whiteindex)) = 255;
white_nuclei = I.*uint8(mask_white);
subplot(3, 3, 8);
imshow(white_nuclei); title("Nuclei");

% Finding the max value of tumor image array to get brightest cluster
max = 0;
min = 0;
for i = 1:400
    for j = 1:400
        for k = 1:3
            if (white_nuclei(i, j, k) > max)
                max = white_nuclei(i, j, k); % update max to greatest value
            else
                min = 0; % keep as black
            end
        end
    end
end
max

% Find the unique values of the image array to check for threshold
C = unique(white_nuclei(1:400, 1:400, 1:3))

% Pick tumor pixels by checking threshold
% The threshold was set by trial-and-error, checking with 31 different
% values from the max. value array, C
for i = 1:400
    for j = 1:400
        for k = 1:3
            if (white_nuclei(i, j, k) > 191)
                white_nuclei(i, j, k) = 255; % highlight as white
            else
                white_nuclei(i, j, k) = 0; % keep as black pixel
            end
        end
    end
end
subplot(3, 3, 9);
imshow(white_nuclei); title("Detected Tumor");

toc

% Histogram of original image
figure;
imhist(I); title('Image Data');