function plott3r_hilbert_A4_safe_rwth_FIXED()
% ==========================================================
% RWTH EV3 Plotter – Hilbert Curve (SAFER / NO FALSE HOMING)
% Fixes:
%   1) Proper homing: press -> back off -> release -> resetTachoCount
%   2) More realistic motor move: bigger tolerance + adaptive timeout
%   3) Stall detection (tacho not changing) -> stop + error
%
% RWTH EV3 API style:
%   ev3 = EV3(); ev3.connect('usb') or ev3.connect;
%   motor.power, motor.start(), motor.stop()
%   motor.tachoCount, motor.resetTachoCount()
%   touch.value
% ==========================================================

clc; clear;

%% ===================== CONNECT =============================
ev3 = EV3();
% ev3.connect('usb');     % if your RWTH API requires it
ev3.connect;             % otherwise this works

%% ===================== PORTS (CHANGE IF NEEDED) ============
mX    = ev3.motorA;      % X axis
mY    = ev3.motorB;      % Y axis
mP    = ev3.motorC;      % Pen motor
touch = ev3.sensor1;     % Touch sensor (endstop)

%% ===================== SETTINGS ============================
% ---- Motor powers (RWTH uses POWER, not speed) ----
Pxy_move = 25;   % movement power
Pxy_home = 12;   % homing power (LOWER = less smashing)
Ppen     = 15;   % pen power

% ---- Scaling (from your Plott3r.ev3) ----
kX = -9;     % degrees per X unit
kY =  8;     % degrees per Y unit

% ---- Pen angles (TUNE these) ----
penUpDeg   = 0;
penDownDeg = 70;

% ---- Homing direction (flip +/- if wrong) ----
homeDirX = -1;
homeDirY = -1;

% ---- If you ONLY have ONE endstop physically for X (common) ----
% set HOME_Y = false (otherwise Y "homes" incorrectly and causes jams)
HOME_X = true;
HOME_Y = true;   % set false if Y does NOT press the touch sensor in real life

% ---- Drawing (safe / small first) ----
order     = 2;     % 2 is safer than 3
stepUnits = 3;     % size of each step in "units"
startX    = 5;
startY    = 5;

% ---- HARD SAFE DRAWING WINDOW (in UNITS) ----
SAFE.minX = 0; SAFE.minY = 0;
SAFE.maxX = 40;    % tune for your paper
SAFE.maxY = 55;    % tune for your paper

% ---- Optional backlash compensation (usually keep 0) ----
backlashX_deg = 0;
backlashY_deg = 0;

%% ===================== INIT ================================
stopAll();
mX.resetTachoCount(); mY.resetTachoCount(); mP.resetTachoCount();

posX_units = 0; posY_units = 0;
curXdeg_virtual = 0; curYdeg_virtual = 0;

penUp();

%% ===================== HOME ================================
if HOME_X || HOME_Y
    disp("Homing...");
    if HOME_X
        disp("  Homing X...");
        homeAxis(mX, touch, Pxy_home, homeDirX);
    end
    if HOME_Y
        disp("  Homing Y...");
        homeAxis(mY, touch, Pxy_home, homeDirY);
    end
    disp("Homing done.");
end

% After homing, treat this as (0,0) for software
mX.resetTachoCount(); mY.resetTachoCount();
posX_units = 0; posY_units = 0;
curXdeg_virtual = 0; curYdeg_virtual = 0;

%% ===================== PRE-CHECK: FIT IN SAFE BOX ==========
sideSteps = (2^order - 1) * stepUnits;
if startX < SAFE.minX || startY < SAFE.minY || ...
   (startX + sideSteps) > SAFE.maxX || (startY + sideSteps) > SAFE.maxY
    error("Hilbert won't fit SAFE box. Reduce order/stepUnits or move startX/startY or increase SAFE.");
end

%% ===================== DRAW ================================
disp("Move to start...");
moveToUnits(startX, startY);

disp("Pen down...");
penDown();

disp("Draw Hilbert...");
drawHilbert(order, stepUnits);

disp("Pen up...");
penUp();

disp("Return to origin (0,0)...");
moveToUnits(0, 0);

disp("DONE.");
stopAll();

%% ===================== NESTED FUNCTIONS ====================

    function stopAll()
        mX.stop(); mY.stop(); mP.stop();
    end

    function emergencyStop(msg)
        try, penUp(); catch, end
        stopAll();
        error(msg);
    end

    function penUp()
        moveMotorToDeg_SAFE(mP, penUpDeg, Ppen, 2.0);
    end

    function penDown()
        moveMotorToDeg_SAFE(mP, penDownDeg, Ppen, 2.0);
    end

    function checkBounds(xU, yU)
        if xU < SAFE.minX || xU > SAFE.maxX || yU < SAFE.minY || yU > SAFE.maxY
            emergencyStop(sprintf("BOUNDARY VIOLATION: target (%.2f,%.2f) outside SAFE box.", xU, yU));
        end
    end

    function moveToUnits(xU, yU)
        checkBounds(xU, yU);
        dx = xU - posX_units;
        dy = yU - posY_units;
        moveRelativeUnits(dx, dy);
        posX_units = xU;
        posY_units = yU;
    end

    function moveRelativeUnits(dxU, dyU)
        nextX = posX_units + dxU;
        nextY = posY_units + dyU;
        checkBounds(nextX, nextY);

        xDeltaDeg = dxU * kX;
        yDeltaDeg = dyU * kY;

        realMove(xDeltaDeg, yDeltaDeg, Pxy_move);

        posX_units = nextX;
        posY_units = nextY;
    end

    function realMove(xDeltaDeg, yDeltaDeg, power)
        xAdj = backlashAdjust(xDeltaDeg, curXdeg_virtual, backlashX_deg);
        yAdj = backlashAdjust(yDeltaDeg, curYdeg_virtual, backlashY_deg);

        moveMotorRelDeg_SAFE(mX, xAdj, power, 6.0);
        moveMotorRelDeg_SAFE(mY, yAdj, power, 6.0);

        curXdeg_virtual = curXdeg_virtual + xDeltaDeg;
        curYdeg_virtual = curYdeg_virtual + yDeltaDeg;
    end

    function drawHilbert(n, stepU)
        % Turtle direction: 0=Right,1=Up,2=Left,3=Down
        dir = 0;

        hilbertA(n);

        function turnLeft(),  dir = mod(dir + 1, 4); end
        function turnRight(), dir = mod(dir + 3, 4); end

        function forward()
            switch dir
                case 0, moveRelativeUnits( stepU, 0);
                case 1, moveRelativeUnits( 0, stepU);
                case 2, moveRelativeUnits(-stepU, 0);
                case 3, moveRelativeUnits( 0,-stepU);
            end
        end

        function hilbertA(k)
            if k == 0, return; end
            turnLeft();
            hilbertB(k-1); forward();
            turnRight();
            hilbertA(k-1); forward();
            hilbertA(k-1); turnRight(); forward();
            hilbertB(k-1);
            turnLeft();
        end

        function hilbertB(k)
            if k == 0, return; end
            turnRight();
            hilbertA(k-1); forward();
            turnLeft();
            hilbertB(k-1); forward();
            hilbertB(k-1); turnLeft(); forward();
            hilbertA(k-1);
            turnRight();
        end
    end

end % end main function

%% ===================== HELPER FUNCTIONS =====================

function homeAxis(m, touch, power, dir)
% Proper homing: press -> back off -> release -> resetTachoCount

    % Phase 1: move toward switch until pressed
    m.power = power * dir;
    m.start();

    t0 = tic;
    while touch.value == 0
        if toc(t0) > 6
            m.stop();
            error("Homing timeout: switch never pressed.");
        end
        pause(0.01);
    end
    m.stop();
    pause(0.15);

    % Phase 2: back off until released
    m.power = power * (-dir);
    m.start();

    t1 = tic;
    while touch.value == 1
        if toc(t1) > 2
            m.stop();
            error("Homing backoff timeout: switch stayed pressed.");
        end
        pause(0.01);
    end
    m.stop();
    pause(0.15);

    % Define this spot as zero
    m.resetTachoCount();
end

function adj = backlashAdjust(deltaDeg, curDeg, backlashDeg)
    if backlashDeg == 0 || deltaDeg == 0
        adj = deltaDeg; return;
    end
    prevDir = sign(curDeg);
    newDir  = sign(deltaDeg);
    if prevDir ~= 0 && newDir ~= 0 && prevDir ~= newDir
        adj = deltaDeg + newDir * backlashDeg;
    else
        adj = deltaDeg;
    end
end

function moveMotorRelDeg_SAFE(m, deltaDeg, power, timeout)
    startDeg = m.tachoCount;
    moveMotorToDeg_SAFE(m, startDeg + deltaDeg, power, timeout);
end

function moveMotorToDeg_SAFE(m, targetDeg, power, timeout)
% Safer move:
%   - bigger tolerance (friction/backlash)
%   - adaptive timeout based on distance
%   - stall detection (tacho not changing)

    tol = 10;  % degrees tolerance (important!)

    startDeg = m.tachoCount;
    dist = abs(targetDeg - startDeg);

    if dist < tol
        return;
    end

    dir = sign(targetDeg - startDeg);
    m.power = power * dir;
    m.start();

    % adaptive timeout: large moves get more time
    maxTime = max(timeout, 0.02*dist + 1.0);

    t0 = tic;
    lastDeg = m.tachoCount;
    stallT0 = tic;

    while abs(targetDeg - m.tachoCount) > tol
        curDeg = m.tachoCount;

        % Stall detection: if not moving for 0.35s -> stop
        if abs(curDeg - lastDeg) < 1
            if toc(stallT0) > 0.35
                m.stop();
                error("Motor stalled (mechanical jam / too much load / low power).");
            end
        else
            stallT0 = tic;
            lastDeg = curDeg;
        end

        if toc(t0) > maxTime
            m.stop();
            error("Motor timeout (could not reach target).");
        end

        pause(0.01);
    end

    m.stop();
end
