% Brain Tumour Detection using MRI Scans on MATLAB

% METHOD - 2 : COLOR MAPPING TO DETECT INTENSE COLORED REGIONS

% Clear the work environment
close all;
clc;
close;

tic % start timer to see duration of code execution

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

% Use Jet Colormapping to indicate regions of higher density with red tint
Ijet = ind2rgb(im2gray(I),jet);
% subplot(3, 3, 4);
% imshow(Ijet); title('Jet Color Mapped Image');

% Use Turbo (more even transitions between color codes than jet) Colormapping 
% to indicate regions of higher density with red tint
Iturbo = ind2rgb(im2gray(I),turbo);
% subplot(1, 2, 2);
% imshow(Iturbo); title('Turbo Color Mapped Image of MRI Scan of Brain');

% Resizing the image
Ijet = imresize(Ijet,[400,400]);
% Iturbo = imresize(Iturbo, [400, 400]);

% Code to color the jet colormapped image
colorijet = 255 * repmat(uint8(Ijet), 1, 1, 3); 
rgbImage = colorijet;

% Read the image data
[rows, columns, nofcolorbands] = size(rgbImage);

% If image is monochrome, convert it to color.
if nofcolorbands == 1
	if isempty(storedColorMap)
		% Create a 3D true color image where we copy the monochrome image into all 3 (R, G, & B) color planes.
		rgbImage = cat(3, rgbImage, rgbImage, rgbImage);
	else
		% Indexed image.
		rgbImage = ind2rgb(rgbImage, storedColorMap);
		% ind2rgb() - convert it to double and normalize it to the range 0-1.
		% Convert back to uint8 in the range 0-255, if needed.
		if eightBit
			rgbImage = uint8(255 * rgbImage);
		end
	end
end
if nofcolorbands > 1
	title('Base Image');
else
	caption = sprintf('The original monochrome image is converted to color using colormap');
	title(caption);
end

% Extract out the color bands from the original image into 3 separate 2D arrays for each color component.
redBand = rgbImage(:, :, 1);
greenBand = rgbImage(:, :, 2);
blueBand = rgbImage(:, :, 3);

% Display of each color band extracted
subplot(3, 3, 4);
imshow(redBand); title('Red Band');
subplot(3, 3, 5);
imshow(greenBand); title('Green Band');
subplot(3, 3, 6);
imshow(blueBand); title('Blue Band');

% Assign the low and high thresholds for each color band.
redThresholdLow = 0;
redThresholdHigh = 255;
greenThresholdLow = 0;
greenThresholdHigh = 0;
blueThresholdLow = 0;
blueThresholdHigh = 0;

% Apply each color band threshold range to the color band
redMask = (redBand >= redThresholdLow) & (redBand <= redThresholdHigh);
greenMask = (greenBand >= greenThresholdLow) & (greenBand <= greenThresholdHigh);
blueMask = (blueBand >= blueThresholdLow) & (blueBand <= blueThresholdHigh);

% % Display the thresholded binary images.
% subplot(2, 3, 4);
% imshow(redMask, []); title('Red Mask');
% subplot(2, 3, 5);
% imshow(greenMask, []); title('Not Green Mask');
% subplot(2, 3, 6);
% imshow(blueMask, []); title('Not Blue Mask');

% Combine the masks to find where all 3 are exist.
% This will give the mask of only the red parts of the image.
redobjectmask = uint8(redMask & greenMask & blueMask);
subplot(3, 3, 8);
imshow(redobjectmask, []); title('Red Objects');

% Filter out small objects
smallestacceptablearea = 60;
% Next we will eliminate regions smaller than smallestAcceptableArea pixels.
% Note: bwareaopen returns a logical.
redobjectmask = uint8(bwareaopen(redobjectmask, smallestacceptablearea));
subplot(3, 3, 7);
imshow(redobjectmask, []);
caption = sprintf('Remove Small Objects');
title(caption);

% Smooth the border using a morphological closing operation, imclose().
structuringelement = strel('disk', 4);
redobjectmask = imclose(redobjectmask, structuringelement);
% subplot(3, 3, 3);
% imshow(redobjectmask, []); title('Border smoothed');

% Fill in any holes in the regions, since they are most likely red also.
redobjectmask = uint8(imfill(redobjectmask, 'holes'));
subplot(3, 3, 8);
imshow(redobjectmask, []); title('Regions Filled');

% This is the filled, size-filtered mask.Now we will apply this mask to the original image.
% redobjectmask is a logical array
% We need to convert it to the same data type as redBand.
redobjectmask = cast(redobjectmask, class(redBand));
% Use the red object mask to mask out the red-only portions of the rgb image.
maskedR = redobjectmask .* redBand;
maskedG = redobjectmask .* greenBand;
maskedB = redobjectmask .* blueBand;

% % Show the masked off red image.
% subplot(3, 3, 5);
% imshow(maskedR); title('Masked Red Image');
% % Show the masked off green image.
% subplot(3, 3, 6);
% imshow(maskedG); title('Masked Green Image');
% % Show the masked off blue image.
% subplot(3, 3, 7);
% imshow(maskedB); title('Masked Blue Image');

% Concatenate the masked color bands to form the rgb image.
maskedimage = cat(3, maskedR, maskedG, maskedB);
% Show the masked off, original image.
subplot(3, 3, 9);
imshow(maskedimage); caption = sprintf('Masked Original Image \nShowing Only the Red Objects');
title(caption);

% Measure the mean RGB and area of all the detected blobs.
[meanRGB, areas, numberOfBlobs] = MeasureBlobs(redobjectmask, redBand, greenBand, blueBand);
if numberOfBlobs > 0
	fprintf(1, '\n----------------------------------------------\n');
	fprintf(1, 'Blob #, Area in Pixels, Mean R, Mean G, Mean B\n');
	fprintf(1, '----------------------------------------------\n');
	for blobNumber = 1 : numberOfBlobs
		fprintf(1, '#%5d, %14d, %6.2f, %6.2f, %6.2f\n', blobNumber, areas(blobNumber), ...
			meanRGB(blobNumber, 1), meanRGB(blobNumber, 2), meanRGB(blobNumber, 3));
	end
else
	% Alert user that no red blobs were found.
	message = sprintf('No red blobs were found in the image:\n%s', fullImageFileName);
	fprintf(1, '\n%s\n', message);
	uiwait(msgbox(message));
end

toc % end timer to see duration of code execution

% Histogram of original image
figure;
imhist(I); title('Image Data');

%----------------------------------------------------------------------------

% Measure the mean intensity and area of each blob in each color band.
function [meanRGB, areas, numberOfBlobs] = MeasureBlobs(maskImage, redBand, greenBand, blueBand)
[labeledImage, numberOfBlobs] = bwlabel(maskImage, 8); % Label each blob so we can make measurements of it
if numberOfBlobs == 0
	% Didn't detect any yellow blobs in this image
	meanRGB = [0 0 0];
	areas = 0;
	return;
end
% Get all the blob properties
blobMeasurementsR = regionprops(labeledImage, redBand, 'area', 'MeanIntensity');
blobMeasurementsG = regionprops(labeledImage, greenBand, 'area', 'MeanIntensity');
blobMeasurementsB = regionprops(labeledImage, blueBand, 'area', 'MeanIntensity');
meanRGB = zeros(numberOfBlobs, 3);  % One row for each blob.  One column for each color.
meanRGB(:,1) = [blobMeasurementsR.MeanIntensity]';
meanRGB(:,2) = [blobMeasurementsG.MeanIntensity]';
meanRGB(:,3) = [blobMeasurementsB.MeanIntensity]';
% If redBand etc. are double, the intensities will be in the range of 0-1.
% Multiply by 255 to get them back into the uint8 range of 0-255.
if ~strcmpi(class(redBand), 'uint8')
	meanRGB = meanRGB * 255.0;
end
% Now assign the areas.
areas = zeros(numberOfBlobs, 3);  % One row for each blob.  One column for each color.
areas(:,1) = [blobMeasurementsR.Area]';
areas(:,2) = [blobMeasurementsG.Area]';
areas(:,3) = [blobMeasurementsB.Area]';
return; % from MeasureBlobs()
end