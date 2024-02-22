%% HOMOBSDETECT Detection of obstacles from homography.

function [blobImage, I1, I2] = homobsdetect(I1, I2, H, stereoParams)
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
end

% Plane and fake camera.
R = stereoParams.PoseCamera2.R;
t = stereoParams.PoseCamera2.Translation;

K1 = stereoParams.CameraParameters1.K;
K2 = stereoParams.CameraParameters2.K;

planeNormal = (t .^ (-1)) / 3 * (-inv(K2) * H.T * K1 + R);
planeNormal = planeNormal ./ norm(planeNormal);

% Let's build a rotation matrix so that the z-axis of the fake camera
% points to the plane (opposite of its normal), and its y-axis (up) is
% vertically aligned with the z-axis.

% fakeCameraZ = [1 1 1];
% fakeCameraY = (eul2rotm([pi/2 0 0]) * fakeCameraZ')';
% fakeCameraX = (eul2rotm([0 pi/2 0]) * fakeCameraZ')';
% 
% fakeR = [fakeCameraX; fakeCameraY; fakeCameraZ];
% 
% quiver3([0 0 0], [0 0 0], [0 0 0], fakeR(:, 1)', fakeR(:, 2)', fakeR(:, 3)');
% axis equal;
% 
% fakeCamera = cameraProjection(stereoParams.CameraParameters1.Intrinsics, rigidtform3d(fakeR, [0 0 0]));
% 
% figure(1);
% plotCamera("AbsolutePose", fakePose);
% hold on;
% quiver3([0 0], [0 0], [0 0], [1 0], [0 0], [0 1]);
% plot(planeModel([planeNormal 0]));
% hold off;
% axis equal;
% 
% fakeCameraHomography = K1 * (fakeCamera(1:3, 1:3) + (fakeCamera(:, end) * planeNormal) ./ d) * inv(K1);
% fakeCameraHomography = projtform2d(fakeCameraHomography);

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
diff = imabsdiff(I1, I2);

% Subtract mask.
mask = mask1(:, :, 1) ~= 0 & mask2(:, :, 1) ~= 0;

% Resize mask.
mask = imresize(mask, 0.5);

% Mask.
diff = diff .* uint8(mask);

% Threshold.
diffTh = im2gray(im2double(diff)) > 0.05;

% Open/close.
seo = strel('disk', 2);
diffTh = imopen(diffTh, seo);

sec = strel('disk', 15);
diffTh = imclose(diffTh, sec);

% Erode.
sede = strel('disk', 2);
diffTh = imerode(diffTh, sede);

% Remove blobs under a certain percentile again.
blobAreas = regionprops(diffTh, 'Area');
blobAreas = [blobAreas.Area];

areaThreshold = prctile(blobAreas, 70, 2);

diffTh = bwareaopen(diffTh, round(areaThreshold));

% Re-dilate.
diffTh = imdilate(diffTh, sede);

blobImage = diffTh;

end
