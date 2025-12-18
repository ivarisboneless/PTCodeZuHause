function plott3r_hilbert_A4_safe_rwth_FIXED_MULTI()
% ==========================================================
% RWTH EV3 Plotter – Hilbert Curve (SAFER) + MULTIPLE CURVES
% Draws MANY Hilbert curves in a grid inside SAFE box.
% ==========================================================

clc; clear;

%% ===================== CONNECT =============================
ev3 = EV3();
ev3.connect;

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
HOME_X = true;
HOME_Y = true;   % set false if Y does NOT press the touch sensor in real life

% ==========================================================
% HILBERT SETTINGS
% ==========================================================
order     = 3;     % more curves than 2
stepUnits = 2;     % smaller steps -> more "curvy look" and safer than huge steps

% ==========================================================
% SAFE DRAWING WINDOW (in UNITS)
% ==========================================================
SAFE.minX = 0; SAFE.minY = 0;
SAFE.maxX = 40;
SAFE.maxY = 55;

% ---- Optional backlash compensation (usually keep 0) ----
backlashX_deg = 0;
backlashY_deg = 0;

% ==========================================================
% MULTI-CURVE SETTINGS (GRID)
% ==========================================================
margin = 2;         % extra space between curves (units)
maxCurves = 100;    % safety cap, won’t draw more than this

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

%% ===================== COMPUTE HOW MANY FIT ================
sideSteps = (2^order - 1) * stepUnits;     % square size in units
cellSize  = sideSteps + margin;            % space per curve in grid

% How many columns/rows fit in SAFE?
nCols = floor((SAFE.maxX - SAFE.minX + 1) / cellSize);
nRows = floor((SAFE.maxY - SAFE.minY + 1) / cellSize);

if nCols < 1 || nRows < 1
    error("Hilbert too big for SAFE. Reduce order or stepUnits, or enlarge SAFE.");
end

total = min(nCols*nRows, maxCurves);
fprintf("Hilbert side=%d units. Grid: %d cols x %d rows => drawing %d curves.\n", sideSteps, nCols, nRows, total);

%% ===================== DRAW MANY HILBERTS ==================
curveCount = 0;

for r = 1:nRows
    for c = 1:nCols
        curveCount = curveCount + 1;
        if curveCount > total
            break;
        end

        % bottom-left corner for this cell
        startX = SAFE.minX + (c-1)*cellSize;
        startY = SAFE.minY + (r-1)*cellSize;

        % Final safety check: ensure curve fits
        if (startX + sideSteps) > SAFE.maxX || (startY + sideSteps) > SAFE.maxY
            continue; % skip if barely out
        end

        fprintf("Drawing curve #%d at start (%d,%d)\n", curveCount, startX, startY);

        moveToUnits(startX, startY);
        penDown();
        drawHilbert(order, stepUnits);
        penUp();

        pause(0.2); % small pause helps stability
    end
end

%% ===================== FINISH ==============================
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
        dir = 0; % 0=Right,1=Up,2=Left,3=Down
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
    tol = 10;

    startDeg = m.tachoCount;
    dist = abs(targetDeg - startDeg);
    if dist < tol, return; end

    dir = sign(targetDeg - startDeg);
    m.power = power * dir;
    m.start();

    maxTime = max(timeout, 0.02*dist + 1.0);

    t0 = tic;
    lastDeg = m.tachoCount;
    stallT0 = tic;

    while abs(targetDeg - m.tachoCount) > tol
        curDeg = m.tachoCount;

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
