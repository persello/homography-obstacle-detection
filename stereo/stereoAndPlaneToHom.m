%% STEREOANDPLANETOHOM Computes plane-induced homography between two cameras.

function H = stereoAndPlaneToHom(plane, stereoParams)
arguments(Input)
    plane (1, 1) planeModel
    stereoParams (1, 1) stereoParameters
end

arguments(Output)
    H projtform2d
end

K1 = stereoParams.CameraParameters1.K;
K2 = stereoParams.CameraParameters2.K;
R = stereoParams.PoseCamera2.R;
t = stereoParams.PoseCamera2.Translation;
d = plane.Parameters(4);

Hmat = K2 * (R + t * plane.Normal' / d) * inv(K1);

H = projtform2d(Hmat);

end