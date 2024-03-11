
close all;

%% Paths

baseFolder = "~/Movies/coderno/";

leftSubfolder = "frames/left";
rightSubfolder = "frames/right";
homographyFile = "homography.mat";
stereoParamsFile = "../stereoParams.mat";

startingFrame = 40;
calibrationFrame = 40;

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
    [blobImage, I1, I2] = homobsdetect(I1, I2, H, toStruct(stereoParams));

    % Write to video
    anaglyph = stereoAnaglyph(I1, I2);

    % Overlay red blobs with transparency
    redBlobs = cat(3, 255 * blobImage, zeros(size(blobImage), "like", anaglyph), zeros(size(blobImage), "like", anaglyph));
    frame = imadd(anaglyph, redBlobs * 0.7, 'uint8');

    imshow(frame);

    writeVideo(vw, frame);
end

vw.close();