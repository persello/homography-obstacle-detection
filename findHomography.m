%% Semi-automatic camera pair pose estimation relative to a ground plane.

close all;
imageFolder = 'images/bib';
imds = imageDatastore(imageFolder);

phoneCamera = load('cameraParams/iPhone_15_ultrawide_12mp.mat');
cameraParams = phoneCamera.cameraParams;

undistortedImages = cell(1, 2);

%% Ask the user to select a region of the image that is the ground plane.
groundPlaneRegion = cell(1, 2);
for i = 1:2
    image = imds.readimage(i);
    undistortedImages{i} = undistortImage(image, cameraParams);
    figure;
    imshow(undistortedImages{i});
    title('Select a region of the image that is the ground plane.');
    roi = drawpolygon('Color', 'r');
    groundPlaneRegion{i} = roi.Position;
end

%% Extract SIFT features and match them.

vSet = imageviewset();
for i = 1:2
    image = imds.readimage(i);
    undistortedImages{i} = undistortImage(image, cameraParams);
    features = detectSIFTFeatures(im2gray(undistortedImages{i}));
    [f, p] = extractFeatures(im2gray(undistortedImages{i}), features);

    % Filter out features that are not in the ground plane region.
    inRegion = inpolygon(p.Location(:, 1), p.Location(:, 2), groundPlaneRegion{i}(:, 1), groundPlaneRegion{i}(:, 2));
    f = f(inRegion, :);
    p = p(inRegion, :);

    vSet = vSet.addView(i, "Features", f, "Points", p);

    if i > 1
        indexPairs = matchFeatures(fPrev, f);
        vSet = vSet.addConnection(i-1, i, "Matches", indexPairs);
    end

    fPrev = f;
end

matches = vSet.findConnection(1, 2).Matches{1};

matchedPoints{1} = vSet.Views(1, :).Points{1}(matches(:, 1), :);
matchedPoints{2} = vSet.Views(2, :).Points{1}(matches(:, 2), :);

figure(1);
showMatchedFeatures(imds.readimage(1), imds.readimage(2), matchedPoints{1}, matchedPoints{2});

%% Compute the relative pose between cameras, in order to extract the inliers.
[fMatrix, epipolarInliers] = estimateFundamentalMatrix(matchedPoints{1}, matchedPoints{2}, 'Method', 'MSAC', 'NumTrials', 20000, 'DistanceThreshold', 0.1);

vSet = vSet.updateConnection(1, 2, "Matches", matches(epipolarInliers, :));

matchedInliers{1} = vSet.Views(1, :).Points{1}(matches(epipolarInliers, 1), :);
matchedInliers{2} = vSet.Views(2, :).Points{1}(matches(epipolarInliers, 2), :);

figure(2);
showMatchedFeatures(undistortedImages{1}, undistortedImages{2}, matchedInliers{1}, matchedInliers{2});

%% Estimate homography.
H = estimateGeometricTransform(matchedInliers{1}, matchedInliers{2}, 'projective');
save(imageFolder + "/homography.mat", "H");