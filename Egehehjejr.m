function drawSquare_RWTH()
% ==========================================================
% RWTH EV3 Plotter – SIMPLE SQUARE (NO PEN UP/DOWN)
% - Motors: X = A, Y = B
% - Optional homing with touch sensor on sensor1
% - Moves by tachoCount (degrees), RWTH "power" control
% ==========================================================

clc; clear;

%% ============ CONNECT ============
ev3 = EV3();
ev3.connect;        % or ev3.connect('usb') if your setup needs it

%% ============ PORTS (CHANGE IF NEEDED) ============
mX    = ev3.motorA;     % X axis motor
mY    = ev3.motorB;     % Y axis motor
touch = ev3.sensor1;    % Touch sensor (endstop)

%% ============ SETTINGS ============
Pmove = 25;          % move power (try 20..35)
Phome = 12;          % homing power (low = less smashing)

% Scaling from your Plott3r.ev3
kX = -9;             % deg per X unit
kY =  8;             % deg per Y unit

% Homing directions (flip if it goes away from switch)
homeDirX = -1;
homeDirY = -1;

HOME_X = true;
HOME_Y = false;      % IMPORTANT: set true only if Y REALLY presses the same touch sensor

% Square parameters (IN UNITS)
startX = 8;          % starting position inside paper (units)
startY = 8;
sideU  = 10;         % square side length (units)

% Safety box (IN UNITS) – keep conservative
SAFE.minX = 0; SAFE.minY = 0;
SAFE.maxX = 40; SAFE.maxY = 55;

%% ============ INIT ============
stopAll();
mX.resetTachoCount(); mY.resetTachoCount();

posX = 0; posY = 0;

%% ============ OPTIONAL HOMING ============
if HOME_X
    disp("Homing X...");
    homeAxis(mX, touch, Phome, homeDirX);
end
if HOME_Y
    disp("Homing Y...");
    homeAxis(mY, touch, Phome, homeDirY);
end
disp("Homing done.");

mX.resetTachoCount(); mY.resetTachoCount();
posX = 0; posY = 0;

%% ============ GO TO START ============
checkBounds(startX, startY);
moveTo(startX, startY);

%% ============ DRAW SQUARE (NO PEN CONTROL) ============
% Path: right, up, left, down back to start
disp("Drawing square...");
moveRel( sideU, 0);
moveRel( 0, sideU);
moveRel(-sideU, 0);
moveRel( 0,-sideU);

disp("Done. Stopping motors.");
stopAll();

%% ================== NESTED ==================

    function stopAll()
        mX.stop(); mY.stop();
    end

    function checkBounds(xU, yU)
        if xU < SAFE.minX || xU > SAFE.maxX || yU < SAFE.minY || yU > SAFE.maxY
            stopAll();
            error("BOUNDARY: target (%.2f, %.2f) outside SAFE.", xU, yU);
        end
    end

    function moveTo(xU, yU)
        dx = xU - posX;
        dy = yU - posY;
        moveRel(dx, dy);
        posX = xU; posY = yU;
    end

    function moveRel(dxU, dyU)
        nextX = posX + dxU;
        nextY = posY + dyU;
        checkBounds(nextX, nextY);

        xDeg = dxU * kX;
        yDeg = dyU * kY;

        % Do X then Y (more reliable than trying to sync)
        moveMotorRelDeg_SAFE(mX, xDeg, Pmove, 6.0);
        moveMotorRelDeg_SAFE(mY, yDeg, Pmove, 6.0);

        posX = nextX;
        posY = nextY;
    end

end

%% ================== HELPERS (OUTSIDE MAIN) ==================

function homeAxis(m, touch, power, dir)
% Press -> back off -> release -> resetTachoCount

    % Approach switch
    m.power = power * dir;
    m.start();

    t0 = tic;
    while touch.value == 0
        if toc(t0) > 6
            m.stop();
            error("Homing timeout: switch never pressed.");
        end
        pause(0.005); % faster polling = less overshoot
    end
    m.stop();
    pause(0.1);

    % Back off until released
    m.power = power * (-dir);
    m.start();

    t1 = tic;
    while touch.value == 1
        if toc(t1) > 2
            m.stop();
            error("Homing backoff timeout: switch stayed pressed.");
        end
        pause(0.005);
    end
    m.stop();
    pause(0.1);

    m.resetTachoCount();
end

function moveMotorRelDeg_SAFE(m, deltaDeg, power, timeout)
    startDeg = m.tachoCount;
    moveMotorToDeg_SAFE(m, startDeg + deltaDeg, power, timeout);
end

function moveMotorToDeg_SAFE(m, targetDeg, power, timeout)
% Safe movement with tolerance + stall detection + adaptive timeout

    tol = 12; % degrees tolerance (important for friction/backlash)
    startDeg = m.tachoCount;
    dist = abs(targetDeg - startDeg);

    if dist < tol
        return;
    end

    dir = sign(targetDeg - startDeg);
    m.power = power * dir;
    m.start();

    maxTime = max(timeout, 0.03*dist + 0.8);  % adapt time to distance

    t0 = tic;
    lastDeg = m.tachoCount;
    stallT0 = tic;

    while abs(targetDeg - m.tachoCount) > tol
        curDeg = m.tachoCount;

        % Stall detect: no movement for 0.35s
        if abs(curDeg - lastDeg) < 1
            if toc(stallT0) > 0.35
                m.stop();
                error("Motor stalled (jam / too much load / power too low).");
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
