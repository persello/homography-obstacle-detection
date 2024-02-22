% CALIBRATEGROUNDPLANE  Extract ground plane from stereo camera

function p = calibrateGroundPlane(aPath, bPath, stereoParams)

arguments(Input)
    aPath {mustBeFile}
    bPath {mustBeFile}
    stereoParams stereoParameters
end

arguments(Output)
    p planeModel
end

close all;

% Load the images.
a = imread(aPath);
b = imread(bPath);

% Undistort.
a = undistortImage(a, stereoParams.CameraParameters1);
b = undistortImage(b, stereoParams.CameraParameters2);

% Rectify the images.
[aRect, bRect] = rectifyStereoImages(a, b, stereoParams);

% Anaglyph.
% an = stereoAnaglyph(aRect, bRect);
% imageViewer(an);

% Disparity map.
disparityRange = [24 128];
disparityMap = disparitySGM(rgb2gray(aRect), rgb2gray(bRect), "DisparityRange", disparityRange);

% Filter out sky.
bluePixels = bRect(:, :, 3) > 200;
disparityMap(bluePixels) = NaN;

figure("Name", "Plane calibration disparity map");
imshow(disparityMap, DisplayRange=disparityRange);
colormap jet;
colorbar;

drawnow;

% Reconstruct.
scene = reconstructScene(disparityMap, stereoParams);
pcloud = pointCloud(scene, "Color", aRect);

figure("Name", "Plane calibration point cloud");
pcloud = pcdenoise(pcloud);
pcshow(pcloud);

drawnow;

% Estimate plane.
interest = pcloud.findPointsInROI([-Inf, Inf, 1000, Inf, 0, 4000]);
p = pcfitplane(pcloud, 10, [0, 1, -0.5], 25, "MaxNumTrials", 100000, "SampleIndices", interest);

hold on;
plot(p);

drawnow;

figure("Name", "Relative poses");
plotCamera("AbsolutePose", rigidtform3d(eye(3), [0 0 0]'), Size=10);
hold on;
plotCamera("AbsolutePose", stereoParams.PoseCamera2, Size=10);
plot(p);

drawnow;

end