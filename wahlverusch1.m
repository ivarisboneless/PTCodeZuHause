function plott3r_hilbert_A4_safe_rwth()
% ==========================================================
% RWTH EV3 Plotter – Hilbert Curve + HARD A4 BOUNDARY CHECK
%
% Uses RWTH EV3 API:
%   ev3 = EV3(); ev3.connect;
%   motor.power, motor.start(), motor.stop()
%   motor.tachoCount, motor.resetTachoCount()
%   touch.value
%
% Movement scaling "as per Plott3r.ev3":
%   xDeg = xUnits * (-9)
%   yDeg = yUnits * ( 8)
% ==========================================================

clc; clear;

%% ===================== CONNECT =============================
ev3 = EV3();
ev3.connect;

%% ===================== PORTS ===============================
mX = ev3.motorA;      % X axis motor
mY = ev3.motorB;      % Y axis motor
mP = ev3.motorC;      % Pen motor
touch = ev3.sensor1;  % Touch sensor (home switch)

%% ===================== SETTINGS ============================
% Motor power
Pxy  = 25;     % axis power
Ppen = 15;     % pen power

% Plott3r.ev3 scaling (IMPORTANT)
kX = -9;       % degrees per X unit
kY =  8;       % degrees per Y unit

% Optional backlash compensation (0 = off)
backlashX_deg = 0;  % try 5..20 only if needed
backlashY_deg = 0;

% Pen angles (tune)
penUpDeg   = 0;
penDownDeg = 70;

% Homing direction (flip if wrong)
homeDirX = -1;
homeDirY = -1;

% ---------- Hilbert parameters ----------
order     = 3;   % recommended: 2 or 3 for exam reliability
stepUnits  = 3;  % try 2 or 3
startX     = 3;  % start position (units) inside safe box
startY     = 3;

% ==========================================================
% HARD SAFE DRAWING WINDOW (in UNITS)
%
% This is your "A4-safe rectangle" in your internal units.
% You must choose it so that the pen never leaves the paper.
%
% Start conservative. If it draws too small, increase maxX/maxY.
% ==========================================================
SAFE.minX = 0;
SAFE.minY = 0;
SAFE.maxX = 40;    % <-- tune (safe default)
SAFE.maxY = 55;    % <-- tune (safe default)

% If your home (0,0) is outside the paper, adjust SAFE min/max accordingly.
% Example: if (0,0) is slightly below-left of paper, keep min at 0 and use margins.

%% ===================== INIT ================================
stopAll();
mX.resetTachoCount(); mY.resetTachoCount(); mP.resetTachoCount();

% Track current position in "units" (this is what boundary check uses)
posX_units = 0;
posY_units = 0;

% Track virtual degrees for backlash direction detection
curXdeg_virtual = 0;
curYdeg_virtual = 0;

penUp();

%% ===================== HOME (RECOMMENDED) ===================
home2D();

mX.resetTachoCount();
mY.resetTachoCount();
posX_units = 0; posY_units = 0;
curXdeg_virtual = 0; curYdeg_virtual = 0;

%% ===================== PRE-CHECK: WILL HILBERT FIT? =========
sideSteps = (2^order - 1) * stepUnits;   % square side length in units

% Hilbert curve will occupy a square of sideSteps. We enforce it fits in SAFE.
if startX < SAFE.minX || startY < SAFE.minY || ...
   (startX + sideSteps) > SAFE.maxX || (startY + sideSteps) > SAFE.maxY
    error("Hilbert will not fit SAFE box. side=%d units. Adjust startX/startY/stepUnits/order or SAFE.max.", sideSteps);
end

%% ===================== DRAW ================================
disp("Moving to start...");
moveToUnits(startX, startY);

disp("Pen down + draw Hilbert...");
penDown();
drawHilbert(order, stepUnits);
penUp();

disp("Return to origin...");
moveToUnits(0, 0);

disp("DONE.");
stopAll();

%% ===================== NESTED FUNCTIONS =====================

    function stopAll()
        mX.stop(); mY.stop(); mP.stop();
    end

    function emergencyStop(msg)
        % HARD STOP behavior: pen up + stop motors + error
        try
            penUp();
        catch
        end
        stopAll();
        error(msg);
    end

    function penUp()
        moveMotorToDeg(mP, penUpDeg, Ppen, 2.0);
    end

    function penDown()
        moveMotorToDeg(mP, penDownDeg, Ppen, 2.0);
    end

    function home2D()
        disp("Homing X...");
        homeAxis(mX, touch, Pxy, homeDirX);
        disp("Homing Y...");
        homeAxis(mY, touch, Pxy, homeDirY);
        disp("Homing done.");
    end

    function checkBounds(xU, yU)
        if xU < SAFE.minX || xU > SAFE.maxX || yU < SAFE.minY || yU > SAFE.maxY
            emergencyStop(sprintf("BOUNDARY VIOLATION: target (%.2f,%.2f) outside SAFE box.", xU, yU));
        end
    end

    function moveToUnits(xU, yU)
        % Hard boundary check
        checkBounds(xU, yU);

        dx = xU - posX_units;
        dy = yU - posY_units;

        moveRelativeUnits(dx, dy);

        posX_units = xU;
        posY_units = yU;
    end

    function moveRelativeUnits(dxU, dyU)
        % Predict next position and enforce hard boundary
        nextX = posX_units + dxU;
        nextY = posY_units + dyU;
        checkBounds(nextX, nextY);

        % Plott3r.ev3 scaling
        xDeltaDeg = dxU * kX;
        yDeltaDeg = dyU * kY;

        realMove(xDeltaDeg, yDeltaDeg, Pxy);

        % Update unit position AFTER a successful move
        posX_units = nextX;
        posY_units = nextY;
    end

    function realMove(xDeltaDeg, yDeltaDeg, power)
        % Backlash adjust + degrees move (sequential for reliability)
        xAdj = backlashAdjust(xDeltaDeg, curXdeg_virtual, backlashX_deg);
        yAdj = backlashAdjust(yDeltaDeg, curYdeg_virtual, backlashY_deg);

        moveMotorRelDeg(mX, xAdj, power, 6.0);
        moveMotorRelDeg(mY, yAdj, power, 6.0);

        curXdeg_virtual = curXdeg_virtual + xDeltaDeg;
        curYdeg_virtual = curYdeg_virtual + yDeltaDeg;
    end

    function drawHilbert(n, stepU)
        % Turtle direction: 0=Right,1=Up,2=Left,3=Down
        dir = 0;

        hilbertA(n);

        function turnLeft()
            dir = mod(dir + 1, 4);
        end
        function turnRight()
            dir = mod(dir + 3, 4);
        end
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

end

%% ===================== HELPER FUNCTIONS ======================

function homeAxis(m, touch, power, dir)
m.power = power * dir;
m.start();

t0 = tic;
while touch.value == 0
    if toc(t0) > 5
        m.stop();
        error("Homing timeout: touch never pressed.");
    end
    pause(0.01);
end

m.stop();
pause(0.2);
end

function adj = backlashAdjust(deltaDeg, curDeg, backlashDeg)
if backlashDeg == 0 || deltaDeg == 0
    adj = deltaDeg;
    return;
end
prevDir = sign(curDeg);
newDir  = sign(deltaDeg);
if prevDir ~= 0 && newDir ~= 0 && prevDir ~= newDir
    adj = deltaDeg + newDir * backlashDeg;
else
    adj = deltaDeg;
end
end

function moveMotorRelDeg(m, deltaDeg, power, timeout)
startDeg = m.tachoCount;
moveMotorToDeg(m, startDeg + deltaDeg, power, timeout);
end

function moveMotorToDeg(m, targetDeg, power, timeout)
dir = sign(targetDeg - m.tachoCount);
if dir == 0
    return;
end
m.power = power * dir;
m.start();

t0 = tic;
while abs(targetDeg - m.tachoCount) > 3
    if toc(t0) > timeout
        m.stop();
        error("Motor timeout (jam / wrong direction / too big move).");
    end
    pause(0.01);
end
m.stop();
end
