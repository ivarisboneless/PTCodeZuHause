function plott3r_rwth_from_ev3()
% ==========================================================
% RWTH MATLAB translation of Plott3r.ev3 (core blocks)
%
% Extracted from .ev3 project:
%   Move_Relative scales:
%       xDeg = Xcoord * (-9)
%       yDeg = Ycoord * ( 8)
%   Then calls _Real_Move:
%       X backlash adjust -> Y backlash adjust -> Degrees_Move2
%
% API (RWTH):
%   ev3 = EV3(); ev3.connect;
%   motor.power, motor.start(), motor.stop()
%   motor.tachoCount, motor.resetTachoCount()
% ==========================================================

clc; clear;

%% -------- CONNECT ----------
ev3 = EV3();
ev3.connect;

%% -------- PORTS (CHANGE IF NEEDED) ----------
mX = ev3.motorA;     % X axis motor
mY = ev3.motorB;     % Y axis motor
mP = ev3.motorC;     % Pen motor
ts = ev3.sensor1;    % Touch sensor (optional homing)

%% -------- SETTINGS ----------
Pxy  = 25;           % power for X/Y
Ppen = 15;           % power for pen

% From your ev3 blocks (Move_Relative):
kX = -9;             % degrees per X "unit"
kY =  8;             % degrees per Y "unit"

% Backlash compensation (small “extra nudge” when changing direction)
% Your project has X_Backlash_Adjust and Y_Backlash_Adjust blocks.
% Start with 0 if you want simplest behavior.
backlashX_deg = 0;   % try 5..20 if you see slack
backlashY_deg = 0;

% Pen positions (degrees)
penUpDeg   = 0;
penDownDeg = 70;

%% -------- INIT ----------
stopAll();
mX.resetTachoCount(); mY.resetTachoCount(); mP.resetTachoCount();

% Track "virtual position" like VirtualXPos / VirtualYPos blocks do:
curXdeg = 0;
curYdeg = 0;

penUp();

%% -------- OPTIONAL: HOME (if your build uses touch for origin) ----------
% If you don't want homing, comment this out.
home2D();

mX.resetTachoCount(); mY.resetTachoCount();
curXdeg = 0; curYdeg = 0;

%% -------- DEMO (matches typical EV3 plotter test) ----------
% Move relative in "units" (the same inputs your EV3 block expects)
moveRelativeUnits( 10,  0);   % right
moveRelativeUnits(  0, 10);   % up
penDown();
moveRelativeUnits(-10,  0);   % left (draw)
moveRelativeUnits(  0,-10);   % down (draw)
penUp();

disp("DONE");

%% ===================== NESTED FUNCTIONS =====================

    function stopAll()
        mX.stop(); mY.stop(); mP.stop();
    end

    function home2D()
        % Very simple homing: drive X until touch pressed, then Y.
        % NOTE: This assumes your touch sensor is placed so it gets pressed
        % at the home corner.
        disp("Homing X...");
        homeAxis(mX, ts, Pxy, -1);
        disp("Homing Y...");
        homeAxis(mY, ts, Pxy, -1);
        disp("Homing done.");
    end

    function penUp()
        moveMotorToDeg(mP, penUpDeg, Ppen, 2.0);
    end

    function penDown()
        moveMotorToDeg(mP, penDownDeg, Ppen, 2.0);
    end

    function moveRelativeUnits(xUnits, yUnits)
        % This is your EV3 "Move_Relative" block translated:
        xDeltaDeg = xUnits * kX;
        yDeltaDeg = yUnits * kY;

        realMove(xDeltaDeg, yDeltaDeg, Pxy);
    end

    function realMove(xDeltaDeg, yDeltaDeg, power)
        % This corresponds to _Real_Move.ev3p (simplified):
        %   X backlash adjust -> Y backlash adjust -> Degrees_Move2

        % Backlash adjust X (only if direction changes)
        xAdj = backlashAdjust(xDeltaDeg, curXdeg, backlashX_deg);

        % Backlash adjust Y
        yAdj = backlashAdjust(yDeltaDeg, curYdeg, backlashY_deg);

        % Degrees_Move2: move both axes by relative degrees (sequential = reliable)
        moveMotorRelDeg(mX, xAdj, power, 6.0);
        moveMotorRelDeg(mY, yAdj, power, 6.0);

        curXdeg = curXdeg + xDeltaDeg;
        curYdeg = curYdeg + yDeltaDeg;
    end

end

%% ===================== HELPER FUNCTIONS =====================

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
% If we change direction, add a small extra move to take up slack.
% This mimics what X_Backlash_Adjust / Y_Backlash_Adjust blocks typically do.

if backlashDeg == 0 || deltaDeg == 0
    adj = deltaDeg;
    return;
end

prevDir = sign(curDeg);         % crude proxy (good enough for backlash use)
newDir  = sign(deltaDeg);

if prevDir ~= 0 && newDir ~= 0 && prevDir ~= newDir
    adj = deltaDeg + newDir * backlashDeg;
else
    adj = deltaDeg;
end
end

function moveMotorRelDeg(m, deltaDeg, power, timeout)
startDeg = m.tachoCount;
target  = startDeg + deltaDeg;
moveMotorToDeg(m, target, power, timeout);
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
