%% HOMOBSDETECT Detection of obstacles from homography.

function [blobImage, I1, I2] = homobsdetect(I1, I2, H, stereoParams)
arguments(Input)
    I1 (:, :, :) uint8 {mustBeNonempty}
    I2 (:, :, :) uint8 {mustBeNonempty}
    H projective2d {mustBeNonempty}
    stereoParams stereoParameters {mustBeNonempty}
end

arguments(Output)
    blobImage (:, :) logical
    I1 (:, :, :) uint8 {mustBeNonempty}
    I2 (:, :, :) uint8 {mustBeNonempty}
end

% Undistort.
I1 = undistortImage(I1, stereoParams.CameraParameters1);
I2 = undistortImage(I2, stereoParams.CameraParameters2);

% Undistort white mask.
white = true(size(I2, [1, 2]));
mask1 = undistortImage(white, stereoParams.CameraParameters1);
mask2 = undistortImage(white, stereoParams.CameraParameters2);

% Rectify.
[I1, I2] = rectifyStereoImages(I1, I2, stereoParams);

% Rectify mask.
[mask1, mask2] = rectifyStereoImages(mask1, mask2, stereoParams);

% Warp.
I1 = imwarp(I1, H, 'OutputView', imref2d(size(I2)));

% Warp mask.
mask1 = imwarp(mask1, H, 'OutputView', imref2d(size(mask2)));

% Subtract.
diff = imabsdiff(I1, I2);

% Subtract mask.
mask = mask1 & mask2;

% Mask.
diff = diff .* uint8(mask);

% Threshold.
diffTh = im2gray(im2double(diff)) > 0.05;

% Blur and threshold again.
% diffTh = imgaussfilt(double(diffTh), 5);
% diffTh = diffTh > 0.9;

% Remove blobs under a certain percentile.
blobAreas = regionprops(diffTh, 'Area');
blobAreas = [blobAreas.Area];

areaThreshold = prctile(blobAreas, 95);

diffTh = bwareaopen(diffTh, round(areaThreshold));

% Close.
se = strel('disk', 5);
diffTh = imopen(diffTh, se);
diffTh = imclose(diffTh, se);

blobImage = diffTh;

end
