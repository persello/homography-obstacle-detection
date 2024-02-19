
close all;

%% Paths

baseFolder = "/Volumes/Samsung 980/GOPRO/coderno/";

leftSubfolder = "frames/left";
rightSubfolder = "frames/right";
homographyFile = "homography.mat";
stereoParamsFile = "../stereoParams.mat";

startingFrame = 30;
calibrationFrame = 60;

%% Loading

% Load stereo parameters
load(baseFolder + stereoParamsFile, 'stereoParams');

% Load imds
imdsL = imageDatastore(baseFolder + leftSubfolder);
imdsR = imageDatastore(baseFolder + rightSubfolder);

% Homography exists?
if ~isfile(baseFolder + homographyFile)
    warning("Homography file not found, please calibrate...");

    H = calibrateGroundHomography(imdsL.Files{calibrationFrame}, imdsR.Files{calibrationFrame}, stereoParams);
    save(baseFolder + homographyFile, 'H');
else
    load(baseFolder + homographyFile, 'H');
end

%% Loop

% Skip to starting frame
for i = 1:startingFrame
    read(imdsL);
    read(imdsR);
end

while imdsL.hasdata() && imdsR.hasdata()
    % Read images
    I1 = read(imdsL);
    I2 = read(imdsR);
    
    % Process
    [blobImage, I1, I2] = homobsdetect(I1, I2, H, stereoParams);
    
    % Create full red image.
    red = cat(3, ones(size(blobImage)), zeros(size(blobImage)), zeros(size(blobImage)));

    % Show
    figure(1);
    imshowpair(I1, I2);
    hold on;
    h = imshow(red);
    set(h, 'AlphaData', blobImage);
    hold off;
end