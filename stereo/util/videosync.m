%% VIDEOSYNC
% This function is used to synchronize stereo videos.
% It shows a frame by frame preview of both videos, and the user can align them.
% KEYS:
% - 'A' and 'Z' to move forward and backward in the first video.
% - 'S' and 'X' to move forward and backward in the second video.
% - 'D' and 'C' to move forward and backward in both videos.
% - enter to save the offset and the output videos.

function videosync(path_a, path_b, path_out)

    % Load videos.
    vid_a = VideoReader(path_a);
    vid_b = VideoReader(path_b);

    % Create figure.
    figure('Name', 'Video Sync', 'NumberTitle', 'off');
    set(gcf, 'Position', get(0, 'Screensize'));

    % Create axes.
    ax_a = subplot(1, 2, 1);
    ax_b = subplot(1, 2, 2);

    % Set title.
    title(ax_a, 'Video A');
    title(ax_b, 'Video B');

    % Main loop.
    id_a = 1;
    id_b = 1;
    while true
        % Show frame.
        frame_a = read(vid_a, id_a);
        frame_b = read(vid_b, id_b);
        imshow(frame_a, 'Parent', ax_a);
        imshow(frame_b, 'Parent', ax_b);

        drawnow;

        % Wait for key.
        waitforbuttonpress;
        key = get(gcf, 'CurrentCharacter');
        set(gcf, 'CurrentCharacter', char(0));

        % Process key.
        switch key
            case 'a'
                id_a = id_a + 1;
            case 'z'
                id_a = id_a - 1;
            case 's'
                id_b = id_b + 1;
            case 'x'
                id_b = id_b - 1;
            case 'd'
                id_a = id_a + 1;
                id_b = id_b + 1;
            case 'c'
                id_a = id_a - 1;
                id_b = id_b - 1;
            case char(13)
                break;
        end
    end

    % Create output folder.
    mkdir(path_out);

    % Save videos starting from the selected frame.
    out_a = VideoWriter(path_out + "/a_sync.mp4", 'MPEG-4');
    out_b = VideoWriter(path_out + "/b_sync.mp4", 'MPEG-4');

    open(out_a);
    open(out_b);

    while hasFrame(vid_a) && hasFrame(vid_b)
        writeVideo(out_a, readFrame(vid_a));
        writeVideo(out_b, readFrame(vid_b));
    end

    close(out_a);
    close(out_b);
end
