%% HOMOBSDETECT Detection of obstacles from homography.

function [blobImage, I1, I2, steps] = homobsdetect(I1, I2, H, stereoParams)
arguments(Input)
    I1 (:, :, :) uint8 {mustBeNonempty}
    I2 (:, :, :) uint8 {mustBeNonempty}
    H (1, 1) projtform2d {mustBeNonempty}
    stereoParams (1, 1) stereoParameters
end

arguments(Output)
    blobImage (:, :) logical
    I1 (:, :, :) uint8 {mustBeNonempty}
    I2 (:, :, :) uint8 {mustBeNonempty}
    % Steps is a cell array of images that represent all the operations that are executed.
    steps cell {mustBeNonempty}
end

% Undistort.
I1 = undistortImage(I1, stereoParams.CameraParameters1);
I2 = undistortImage(I2, stereoParams.CameraParameters2);

% Undistort white mask.
white = 255 * ones(size(I1), "like", I1);
mask1 = undistortImage(white, stereoParams.CameraParameters1);
mask2 = undistortImage(white, stereoParams.CameraParameters2);

% Rectify.
[I1, I2] = rectifyStereoImages(I1, I2, stereoParams);

% Rectify mask.
[mask1, mask2] = rectifyStereoImages(mask1, mask2, stereoParams);

% Warp.
I1 = imwarp(I1, H, 'OutputView', imref2d(size(I2)));

% Resize images.
I1 = imresize(I1, 0.5);
I2 = imresize(I2, 0.5);

% Warp mask.
mask1 = imwarp(mask1, H, 'OutputView', imref2d(size(mask2)));

% Subtract.
steps{1} = imabsdiff(I1, I2);

% Subtract mask.
mask = mask1(:, :, 1) ~= 0 & mask2(:, :, 1) ~= 0;

% Resize mask.
mask = imresize(mask, 0.5);

% Mask.
steps{2} = steps{1} .* uint8(mask);

% Threshold.
steps{3} = im2gray(im2double(steps{2})) > 0.05;

% Open/close.
seo = strel('disk', 2);
steps{4} = imopen(steps{3}, seo);

sec = strel('disk', 15);
steps{5} = imclose(steps{4}, sec);

% Erode.
sede = strel('disk', 2);
steps{6} = imerode(steps{5}, sede);

% Remove blobs under a certain percentile again.
blobAreas = regionprops(steps{6}, 'Area');
blobAreas = [blobAreas.Area];

areaThreshold = prctile(blobAreas, 70, 2);

steps{7} = bwareaopen(steps{6}, round(areaThreshold));

% Re-dilate.
steps{8} = imdilate(steps{7}, sede);

blobImage = steps{end};

end
