function plott3r_square_safe_rwth()
% ==========================================================
% RWTH EV3 Plotter – SUPER SAFE SQUARE TEST
% - Draws a simple square (best for debugging)
% - HARD stop on ANY error (motors never run forever)
% - Stall detection (tacho not changing) + timeout
% - Homing X only by default (set HOME_Y true only if real)
% ==========================================================

clc; clear;

%% ---------- CONNECT ----------
ev3 = EV3();
ev3.connect;     % or ev3.connect('usb') if your setup requires

%% ---------- PORTS (CHANGE IF NEEDED) ----------
mX    = ev3.motorA;      % X axis
mY    = ev3.motorB;      % Y axis
mP    = ev3.motorC;      % pen motor
touch = ev3.sensor1;     % touch sensor

%% ---------- SETTINGS ----------
Pxy_move = 28;     % increase if it stalls (try 25..40)
Pxy_home = 12;     % gentle homing power
Ppen     = 15;

% scaling from your plott3r
kX = -9;     % degrees per X unit
kY =  8;     % degrees per Y unit

penUpDeg   = 0;
penDownDeg = 70;

homeDirX = -1;     % flip if wrong
homeDirY = -1;     % flip if wrong

HOME_X = true;
HOME_Y = false;    % IMPORTANT: set true ONLY if Y physically hits the touch sensor

% square size in "units"
squareSide_units = 12;   % start small, then increase

% start point (units)
startX = 5;
startY = 5;

% very conservative paper-safe box in units
SAFE.minX = 0; SAFE.minY = 0;
SAFE.maxX = 40;
SAFE.maxY = 55;

%% ---------- ALWAYS STOP MOTORS ON EXIT/ERROR ----------
cleanup = onCleanup(@()hardStop(mX,mY,mP));

%% ---------- INIT ----------
hardStop(mX,mY,mP);
mX.resetTachoCount(); mY.resetTachoCount(); mP.resetTachoCount();

posX = 0; posY = 0;   % in units

penUp();

%% ---------- HOME ----------
if HOME_X
    disp("Homing X...");
    homeAxisPressRelease(mX, touch, Pxy_home, homeDirX);
end
if HOME_Y
    disp("Homing Y...");
    homeAxisPressRelease(mY, touch, Pxy_home, homeDirY);
end
disp("Homing done.");

% define home = (0,0)
mX.resetTachoCount(); mY.resetTachoCount();
posX = 0; posY = 0;

%% ---------- MOVE TO START ----------
moveTo(startX, startY);

%% ---------- DRAW SQUARE ----------
penDown();

moveRel(squareSide_units, 0);   % right
moveRel(0, squareSide_units);   % up
moveRel(-squareSide_units, 0);  % left
moveRel(0, -squareSide_units);  % down

penUp();

%% ---------- RETURN ----------
moveTo(0,0);

disp("DONE (square).");

%% ============= nested helpers =============

    function penUp()
        moveMotorToDeg_SAFE(mP, penUpDeg, Ppen);
    end

    function penDown()
        moveMotorToDeg_SAFE(mP, penDownDeg, Ppen);
    end

    function moveTo(xU,yU)
        checkBounds(xU,yU);
        moveRel(xU-posX, yU-posY);
    end

    function moveRel(dxU,dyU)
        nextX = posX + dxU;
        nextY = posY + dyU;
        checkBounds(nextX,nextY);

        xDeg = dxU * kX;
        yDeg = dyU * kY;

        % sequential moves = less coupling, easier debugging
        moveMotorRelDeg_SAFE(mX, xDeg, Pxy_move);
        moveMotorRelDeg_SAFE(mY, yDeg, Pxy_move);

        posX = nextX;
        posY = nextY;
    end

    function checkBounds(xU,yU)
        if xU<SAFE.minX || xU>SAFE.maxX || yU<SAFE.minY || yU>SAFE.maxY
            error("BOUNDARY: (%.1f,%.1f) outside SAFE box", xU,yU);
        end
    end

end

%% ===================== OUTSIDE FUNCTIONS =====================

function hardStop(mX,mY,mP)
% Always safe to call (even if already stopped)
try, mX.stop(); catch, end
try, mY.stop(); catch, end
try, mP.stop(); catch, end
end

function homeAxisPressRelease(m, touch, power, dir)
% Press switch, then release switch, then reset tacho.
m.power = power*dir;
m.start();

t0 = tic;
while touch.value == 0
    if toc(t0) > 6
        m.stop();
        error("HOME timeout: switch not pressed.");
    end
    pause(0.01);
end
m.stop();
pause(0.15);

% back off until released
m.power = power*(-dir);
m.start();

t1 = tic;
while touch.value == 1
    if toc(t1) > 2
        m.stop();
        error("HOME backoff timeout: switch stuck pressed.");
    end
    pause(0.01);
end
m.stop();
pause(0.15);

m.resetTachoCount();
end

function moveMotorRelDeg_SAFE(m, deltaDeg, power)
startDeg = m.tachoCount;
moveMotorToDeg_SAFE(m, startDeg + deltaDeg, power);
end

function moveMotorToDeg_SAFE(m, targetDeg, power)
% NEVER RUNS FOREVER:
% - timeout depends on distance
% - stall detection if tacho not changing

tol = 12;  % degrees tolerance (bigger = less false “stuck”)
startDeg = m.tachoCount;
dist = abs(targetDeg - startDeg);
if dist < tol, return; end

dir = sign(targetDeg - startDeg);
m.power = power*dir;
m.start();

maxTime = max(2.0, 0.03*dist + 1.0);  % adaptive
t0 = tic;

lastDeg = m.tachoCount;
stallT0 = tic;

while abs(targetDeg - m.tachoCount) > tol
    curDeg = m.tachoCount;

    % stall detection: not moving
    if abs(curDeg - lastDeg) < 1
        if toc(stallT0) > 0.35
            m.stop();
            error("STALL: motor not moving (jam / too low power / wrong direction).");
        end
    else
        stallT0 = tic;
        lastDeg = curDeg;
    end

    if toc(t0) > maxTime
        m.stop();
        error("TIMEOUT: could not reach target.");
    end

    pause(0.01);
end

m.stop();
end
