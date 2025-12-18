function square1()


clc; clear;

ev3 = EV3();
ev3.connect('usb');

%% ---- MOTORS ----
mX = ev3.motorA;          % X axis
mY = ev3.motorC;          % Y axis

Pmove = 30;               % 25..45 (raise if it stalls)

% Degrees per "unit" (your plotter scaling)
kX = -9;
kY =  8;

% If your square goes the wrong way, flip these:
flipX = +1;               % set -1 to reverse X
flipY = +1;               % set -1 to reverse Y

sideU = 6;                % square size in units (small = reliable)

% SAFETY: ALWAYS STOP MOTORS
cleanup = onCleanup(@()stopAll(mX,mY));


stopAll(mX,mY);
mX.resetTachoCount();
mY.resetTachoCount();

disp("Drawing EXAM-SAFE square...");

% SQUARE PATH:
moveRel(mX, +sideU, Pmove, kX*flipX);
moveRel(mY, +sideU, Pmove, kY*flipY);
moveRel(mX, -sideU, Pmove, kX*flipX);
moveRel(mY, -sideU, Pmove, kY*flipY);

stopAll(mX,mY);
disp("DONE.");

end

function stopAll(mX,mY)
try, mX.stop(); end
try, mY.stop(); end
end

function moveRel(m, dU, power, k)
% Move motor m by dU units with scale k (deg/unit).
target = m.tachoCount + dU * k;
moveToDeg_safe(m, target, power);
end

function moveToDeg_safe(m, targetDeg, power)
% Safe position move:
% - tolerance to avoid hunting
% - adaptive timeout
% - stall detection (tacho not changing)

tol = 12;                         % deg tolerance
startDeg = m.tachoCount;
dist = abs(targetDeg - startDeg);

if dist < tol
    return;
end

dir = sign(targetDeg - startDeg);
m.power = power * dir;
m.start();

maxTime = max(2.0, 0.03*dist + 0.8);  % adaptive timeout
t0 = tic;

lastDeg = m.tachoCount;
stallT0 = tic;

while abs(targetDeg - m.tachoCount) > tol
    curDeg = m.tachoCount;

    % Stall: if tacho not changing for 0.35s -> stop
    if abs(curDeg - lastDeg) < 1
        if toc(stallT0) > 0.35
            m.stop();
            error("STALL: motor not moving (jam / wrong port / too low power).");
        end
    else
        stallT0 = tic;
        lastDeg = curDeg;
    end

    if toc(t0) > maxTime
        m.stop();
        error("TIMEOUT: could not reach target (load too high or wrong direction).");
    end

    pause(0.01);
end

m.stop();
end
