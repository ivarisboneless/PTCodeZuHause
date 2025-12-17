function plott3r_hilbert_rwth()
% ==========================================================
% RWTH EV3 Plotter – Hilbert Curve
% Translated "as per Plott3r.ev3" motion scaling:
%   xDeg = xUnits * (-9)
%   yDeg = yUnits * ( 8)
%
% RWTH API:
%   ev3 = EV3(); ev3.connect;
%   motor.power, motor.start(), motor.stop()
%   motor.tachoCount, motor.resetTachoCount()
%   touch.value
% ==========================================================

clc; clear;

%% ===================== CONNECT =============================
ev3 = EV3();
ev3.connect;   % RWTH default connection

%% ===================== PORTS ===============================
% CHANGE ONLY HERE IF NEEDED
mX = ev3.motorA;      % X axis motor
mY = ev3.motorB;      % Y axis motor
mP = ev3.motorC;      % Pen motor
touch = ev3.sensor1;  % Touch sensor (for homing)

%% ===================== SETTINGS ============================
% Motor power (RWTH uses power, not speed)
Pxy  = 25;      % axis power (20–35 typical)
Ppen = 15;      % pen power

% --- Plott3r.ev3 scaling (IMPORTANT) ---
kX = -9;        % degrees per X unit (from your EV3 file)
kY =  8;        % degrees per Y unit (from your EV3 file)

% Optional backlash compensation (set 0 if you want simplest)
backlashX_deg = 0;  % try 5..20 if slack shows
backlashY_deg = 0;

% Pen angles (tune to your build)
penUpDeg   = 0;
penDownDeg = 70;

% Homing directions (flip sign if it moves away from the switch)
homeDirX = -1;
homeDirY = -1;

% ---------- Hilbert parameters ----------
order     = 3;   % 1..4 recommended for exam (3 is safe)
stepUnits  = 2;  % step length in "units" (tune: 1..4)
startX     = 2;  % where to start on paper (units)
startY     = 2;

%% ===================== INIT ================================
stopAll();
mX.resetTachoCount(); mY.resetTachoCount(); mP.resetTachoCount();

% Track "virtual position" like VirtualXPos/VirtualYPos conceptually
posX_units = 0;
posY_units = 0;

% Track approximate direction history for backlash (optional)
curXdeg_virtual = 0;
curYdeg_virtual = 0;

penUp();

%% ===================== HOME (OPTIONAL BUT RECOMMENDED) ======
% Comment this out if you do NOT have a proper home switch corner.
home2D();

mX.resetTachoCount();
mY.resetTachoCount();
posX_units = 0; posY_units = 0;
curXdeg_virtual = 0; curYdeg_virtual = 0;

%% ===================== DRAW HILBERT =========================
disp("Going to start position...");
moveToUnits(startX, startY);

disp("Drawing Hilbert curve...");
penDown();
drawHilbert(order, stepUnits);
penUp();

disp("Returning to origin...");
moveToUnits(0, 0);

disp("DONE.");
stopAll();

%% ===================== NESTED FUNCTIONS =====================

    function stopAll()
        mX.stop(); mY.stop(); mP.stop();
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

    function moveToUnits(xU, yU)
        dx = xU - posX_units;
        dy = yU - posY_units;
        moveRelativeUnits(dx, dy);
        posX_units = xU;
        posY_units = yU;
    end

    function moveRelativeUnits(xUnits, yUnits)
        % This is your EV3 "Move_Relative" behavior:
        % xDeg = xUnits * (-9)
        % yDeg = yUnits * ( 8)
        xDeltaDeg = xUnits * kX;
        yDeltaDeg = yUnits * kY;

        realMove(xDeltaDeg, yDeltaDeg, Pxy);
    end

    function realMove(xDeltaDeg, yDeltaDeg, power)
        % Mirrors the idea of _Real_Move + backlash adjust + Degrees_Move2

        xAdj = backlashAdjust(xDeltaDeg, curXdeg_virtual, backlashX_deg);
        yAdj = backlashAdjust(yDeltaDeg, curYdeg_virtual, backlashY_deg);

        % Move axes (sequential = simplest & reliable)
        moveMotorRelDeg(mX, xAdj, power, 6.0);
        moveMotorRelDeg(mY, yAdj, power, 6.0);

        % Update virtual degrees (for backlash direction detection)
        curXdeg_virtual = curXdeg_virtual + xDeltaDeg;
        curYdeg_virtual = curYdeg_virtual + yDeltaDeg;
    end

    % ---------------- Hilbert generator ----------------
    function drawHilbert(n, stepU)
        % Turtle state: direction 0=Right, 1=Up, 2=Left, 3=Down
        dir = 0; % start facing Right

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

        % Classic mutually-recursive Hilbert A/B
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

%% ===================== HELPER FUNCTIONS (RWTH) ===============

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
% If direction changes, add a small extra move to take up slack.
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
