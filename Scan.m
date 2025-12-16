function scan_ultra_rotate_find(conn)
% Rotate motor with ultrasonic sensor and find best direction.
% Best direction here = MAX distance (most open space).
%
% conn: 'usb' or 'bluetooth'

if nargin < 1, conn = 'usb'; end

% --- Connect ---
ev3 = legoev3(conn);

% --- Devices (change ports if needed) ---
rot = ev3.motorC;       % motor that rotates the sensor
us  = ev3.sensor4;      % ultrasonic on port 4

us.mode = DeviceMode.UltraSonic.DistCM;

rot.speedRegulation = 'Off';
rot.brakeMode = 'Brake';
rot.power = 15;

% --- Scan settings ---
stepDeg = 5;
angles  = 0:stepDeg:355;

theta = deg2rad(angles);
rho   = nan(size(angles));

% Start at 0 deg
resetRotation(rot);

% --- Scan loop ---
for k = 1:numel(angles)
    target = angles(k);

    rotateTo(rot, target);

    d = us.value;

    % Handle "no echo"
    if d == 255
        d = NaN;
    end

    % Optional: clip very far readings for nicer plots
    if ~isnan(d) && d > 100
        d = 100;
    end

    rho(k) = d;
    pause(0.03);
end

% --- Decide direction ---
% Option A: most open space (EXIT direction)
[bestDist, idx] = max(rho);  % ignores NaN automatically? (No)
% So do it safely:
valid = ~isnan(rho);
[bestDist, relIdx] = max(rho(valid));
idxValid = find(valid);
idx = idxValid(relIdx);

bestAngle = angles(idx);

fprintf("Best direction: %.0f deg, distance ~ %.1f cm\n", bestAngle, bestDist);

% --- Rotate sensor back to best direction ---
rotateTo(rot, bestAngle);

% --- Plot environment (polar) ---
rhoPlot = rho;
rhoPlot(isnan(rhoPlot)) = 100; % show unknown as "far" for plotting

figure;
polarplot(theta, rhoPlot, '.-');
title('Ultrasonic scan (clipped, NaN->100 for display)');

end

function rotateTo(m, targetDeg)
% Rotate motor until tacho reaches targetDeg (simple absolute control)
m.start();
while readRotation(m) < targetDeg
    pause(0.01);
end
m.stop();
end
