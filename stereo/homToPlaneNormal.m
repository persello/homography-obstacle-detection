%% HOMTOPLANENORMAL Compute the normal of a homography plane

function n = homToPlaneNormal(H, stereoParams)

    arguments(Input)
        H (1, 1) projtform2d
        stereoParams (1, 1)
    end

    arguments(Output)
        n (3, 1) double {mustBeReal, mustBeFinite}
    end

    % H = K2 * (R + t * n' / d) * inv(K1)
    % n = [inv(t1) inv(t2) inv(t3)] / 3 * (inv(K2) * H * K1 - R)

    R = stereoParams.PoseCamera2.R;
    t = stereoParams.PoseCamera2.Translation;

    K1 = stereoParams.CameraParameters1.K;
    K2 = stereoParams.CameraParameters2.K;

    n = (t .^ -1 / 3) * (inv(K2) * H.T * K1 + R);
end