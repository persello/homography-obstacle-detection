%% EXTRACTFRAMESSTEREO
% Extracts frames from a pair of stereo videos.

function extractframesstereo(input_folder, output_folder, skip, count)

    % Check that the input folder contains two videos.
    video_files = dir(fullfile(input_folder, '*.mp4'));

    % Remove hidden files.
    video_files = video_files(~startsWith({video_files.name}, '.'));

    if length(video_files) ~= 2
        error('Input folder must contain exactly two videos.');
    end

    % Create the output folder if it doesn't exist.
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % Create the output folders for the left and right videos, with the same name as the input videos.
    for i = 1:2
        [~, name, ~] = fileparts(video_files(i).name);

        % Keep only the name of the video, without the extension.
        names{i} = name;

        mkdir(fullfile(output_folder, names{i}));
    end

    % Open the videos.
    video_left = VideoReader(fullfile(input_folder, video_files(1).name));
    video_right = VideoReader(fullfile(input_folder, video_files(2).name));

    count = min([count, floor(video_left.NumFrames / (skip + 1)), floor(video_right.NumFrames / (skip + 1))]);

    % Extract the frames.
    parfor i = 1:count
        % Read the frames.
        frame_left = read(video_left, (i - 1) * skip + 1);
        frame_right = read(video_right, (i - 1) * skip + 1);

        % Save the frames.
        imwrite(frame_left, fullfile(output_folder, names{1}, sprintf('%04d.png', i)));
        imwrite(frame_right, fullfile(output_folder, names{2}, sprintf('%04d.png', i)));
    end
end