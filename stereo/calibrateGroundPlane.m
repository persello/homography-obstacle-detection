% CALIBRATEGROUNDPLANE  Extract ground plane from stereo camera

function p = calibrateGroundPlane(aPath, bPath, stereoParams, normal)

arguments(Input)
    aPath {mustBeFile}
    bPath {mustBeFile}
    stereoParams stereoParameters
    normal (1, 3) {mustBeReal}
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
disparityRange = [0 64];
disparityMap = disparitySGM(rgb2gray(aRect), rgb2gray(bRect), "DisparityRange", disparityRange);

figure("Name", "Plane calibration disparity map");
imshow(disparityMap, DisplayRange=disparityRange);
colormap jet;
colorbar;

drawnow;

% Let the user select a polygonal region of interest (ROI).
roi = drawpolygon("Color", "r");

% NaN outside the ROI.
mask = poly2mask(roi.Position(:, 1), roi.Position(:, 2), size(disparityMap, 1), size(disparityMap, 2));
disparityMap(~mask) = NaN;

% Reconstruct.
scene = reconstructScene(disparityMap, stereoParams);
pcloud = pointCloud(scene, "Color", aRect);

figure("Name", "Plane calibration point cloud");
pcloud = pcdenoise(pcloud);
pcshow(pcloud);

drawnow;

% Estimate plane.
p = pcfitplane(pcloud, 100, normal, 1, "MaxNumTrials", 100000);

hold on;
plot(p);

drawnow;

end