
close all;

%% Paths

baseFolder = "/Volumes/Samsung 980/GOPRO/coderno/";

leftSubfolder = "frames/left";
rightSubfolder = "frames/right";
homographyFile = "homography.mat";
stereoParamsFile = "../stereoParams.mat";

startingFrame = 236;
calibrationFrame = 236;

vw = VideoWriter("output", "MPEG-4");
vw.FrameRate = 10;
vw.open();

%% Loading

% Load stereo parameters
load(baseFolder + stereoParamsFile, 'stereoParams');

% Load imds
imdsL = imageDatastore(baseFolder + leftSubfolder);
imdsR = imageDatastore(baseFolder + rightSubfolder);

% Homography exists?
if true %~isfile(baseFolder + homographyFile)
    warning("Homography file not found, please calibrate...");

    % H = calibrateGroundHomography(imdsL.Files{calibrationFrame}, imdsR.Files{calibrationFrame}, stereoParams);
    % n = homToPlaneNormal(H, stereoParams);
    % plane = calibrateGroundPlane(imdsL.Files{calibrationFrame}, imdsR.Files{calibrationFrame}, stereoParams, n);
    % H2 = stereoAndPlaneToHom(plane, stereoParams);

    save(baseFolder + homographyFile, 'H', 'plane');
else
    load(baseFolder + homographyFile, 'H', 'plane');
end

%% Loop

% Skip to starting frame
for i = 1:startingFrame
    read(imdsL);
    read(imdsR);
end

while imdsL.hasdata() && imdsR.hasdata()
%for i = 1:1
    % Read images
    I1 = read(imdsL);
    I2 = read(imdsR);
    
    % Process
    [blobImage, I1, I2] = homobsdetect(I1, I2, H, toStruct(stereoParams));
    
    % Create full red image.
    red = cat(3, ones(size(blobImage)), zeros(size(blobImage)), zeros(size(blobImage)));

    % Show
    figure(1);
    imshowpair(I1, I2);
    hold on;
    h = imshow(red);
    set(h, 'AlphaData', blobImage / 3);
    hold off;

    % Write to video
    anaglyph = stereoAnaglyph(I1, I2);


    % vw.writeVideo(frame);
end

vw.close();