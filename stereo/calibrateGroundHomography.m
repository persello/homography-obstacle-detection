% CALIBRATEGROUNDHOMOGRAPHY  Calibrate a ground plane homography

function H = calibrateGroundHomography(aPath, bPath, stereoParams, mode)

arguments(Input)
    aPath {mustBeFile}
    bPath {mustBeFile}
    stereoParams stereoParameters
    % Mode can be manual or sift.
    mode (1, :) char {mustBeMember(mode, ["manual", "sift"])} = "manual"
end

arguments(Output)
    H projective2d
end

% Load the images.
a = imread(aPath);
b = imread(bPath);

% Undistort.
a = undistortImage(a, stereoParams.CameraParameters1);
b = undistortImage(b, stereoParams.CameraParameters2);

% Rectify the images.
[aRect, bRect] = rectifyStereoImages(a, b, stereoParams);

undistortedImages = {aRect, bRect};
vSet = imageviewset();

if mode == "sift"
    groundPlaneRegion = cell(1, 2);
    
    for i = 1:2
        imshow(undistortedImages{i});
        title('Select a region of the image that is the ground plane.');
        roi = drawpolygon('Color', 'r');
        groundPlaneRegion{i} = roi.Position;
    end
    
    % Extract SIFT features and match them.
    for i = 1:2
        features = detectSIFTFeatures(im2gray(undistortedImages{i}), "ContrastThreshold", 0.001);
        [f, p] = extractFeatures(im2gray(undistortedImages{i}), features);
        
        % Plot the detected points.
        figure("Name", "Detected points");
        imshow(undistortedImages{i});
        hold on;
        plot(p);
        drawnow;
        
        pause;
        
        % Filter the points to the ground plane region.
        inPlane = inpolygon(p.Location(:, 1), p.Location(:, 2), groundPlaneRegion{i}(:, 1), groundPlaneRegion{i}(:, 2));
        f = f(inPlane, :);
        p = p(inPlane, :);
        
        
        % Plot the filtered points.
        figure("Name", "Detected points, filtered by region");
        imshow(undistortedImages{i});
        hold on;
        plot(p);
        drawnow;
        
        pause;
        
        vSet = vSet.addView(i, "Features", f, "Points", p);
        
        if i > 1
            indexPairs = matchFeatures(fPrev, f, "MaxRatio", 1, "Unique", true);
            vSet = vSet.addConnection(i-1, i, "Matches", indexPairs);
        end
        
        fPrev = f;
    end
    
    matches = vSet.findConnection(1, 2).Matches{1};
    
    matchedPoints{1} = vSet.Views(1, :).Points{1}(matches(:, 1), :).Location;
    matchedPoints{2} = vSet.Views(2, :).Points{1}(matches(:, 2), :).Location;
    
    figure("Name", "Matched features");
    showMatchedFeatures(undistortedImages{1}, undistortedImages{2}, matchedPoints{1}, matchedPoints{2});
else
    % Manually select points by alternatingly showing the images and asking the user to select points.
    % To exit the loop, press enter without selecting any points.

    matchedPoints = cell(1, 2);

    while true
        for i = 1:2
            figure(1);
            
            imshow(undistortedImages{i});
            title("Select a point on image " + i);

            points = ginput(1);

            if isempty(points)
                break;
            end

            matchedPoints{i} = [matchedPoints{i}; points];
        end

        if isempty(points)
            break;
        end
    end

    vSet = vSet.addView(1, "Points", matchedPoints{1});
    vSet = vSet.addView(2, "Points", matchedPoints{2});
    matches = [1:size(matchedPoints{1}, 1); 1:size(matchedPoints{1}, 1)]';
    vSet = vSet.addConnection(1, 2, "Matches", matches);
end

% Compute the fundamental matrix and remove outliers.
[~, epipolarInliers] = estimateFundamentalMatrix(matchedPoints{1}, matchedPoints{2}, 'Method', 'MSAC', 'NumTrials', 20000, 'DistanceThreshold', 0.1);

vSet = vSet.updateConnection(1, 2, "Matches", matches(epipolarInliers, :));

matchedInliers{1} = vSet.Views(1, :).Points{1}(matches(epipolarInliers, 1), :);
matchedInliers{2} = vSet.Views(2, :).Points{1}(matches(epipolarInliers, 2), :);

figure("Name", "Matched features after MSAC");
showMatchedFeatures(undistortedImages{1}, undistortedImages{2}, matchedInliers{1}, matchedInliers{2});

% Estimate homography.
H = estimateGeometricTransform(matchedInliers{1}, matchedInliers{2}, 'projective');

end