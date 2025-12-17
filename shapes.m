function rwth_plotter_shapes()
% ==========================================================
% RWTH EV3 Plotter – Square Spiral & Lissajous Curve
% FULL, EXAM-SAFE VERSION
%
% API:
%   ev3 = EV3(); ev3.connect;
%   motor.power, motor.start(), motor.stop()
%   motor.tachoCount, motor.resetTachoCount()
%
% Movement scaling (from Plott3r.ev3):
%   xDeg = xUnits * (-9)
%   yDeg = yUnits * ( 8)
% ==========================================================

clc; clear;

%% ===================== CONNECT =============================
ev3 = EV3();
ev3.connect;

%% ===================== PORTS ===============================
mX = ev3.motorA;      % X axis
mY = ev3.motorB;      % Y axis
mP = ev3.motorC;      % Pen motor
touch = ev3.sensor1;  % Touch sensor

%% ===================== PARAMETERS ==========================
Pxy  = 25;     % motor power for X/Y
Ppen = 15;     % motor power for pen

kX = -9;       % degrees per X unit
kY =  8;       % degrees per Y unit

penUpDeg   = 0;
penDownDeg = 70;

homeDirX = -1;
homeDirY = -1;

%% ===================== INIT ================================
stopAll();
mX.resetTachoCount();
mY.resetTachoCount();
mP.resetTachoCount();

posX = 0;   % current position in units
posY = 0;

penUp();

%% ===================== HOME ================================
homeAxis(mX, touch, Pxy, homeDirX);
homeAxis(mY, touch, Pxy, homeDirY);

mX.resetTachoCount();
mY.resetTachoCount();
posX = 0; posY = 0;

%% ===================== CHOOSE SHAPE ========================
% CHANGE ONLY THIS BLOCK FOR THE DEMO

moveTo(5, 5);    % safe start position on A4

% -------- OPTION 1: SQUARE SPIRAL --------
drawSquareSpiral(10, 2, 1);

% -------- OPTION 2: LISSAJOUS CURVE -------
% drawLissajous(10, 12, 3, 2, pi/2, 300);

%% ===================== FINISH ==============================
penUp();
moveTo(0,0);
stopAll();
disp("DONE");

%% ===================== FUNCTIONS ===========================

    function stopAll()
        mX.stop(); mY.stop(); mP.stop();
    end

    function penUp()
        moveMotorTo(mP, penUpDeg, Ppen);
    end

    function penDown()
        moveMotorTo(mP, penDownDeg, Ppen);
    end

    function homeAxis(m, ts, power, dir)
        m.power = power * dir;
        m.start();
        while ts.value == 0
            pause(0.01);
        end
        m.stop();
        pause(0.2);
    end

    function moveTo(x, y)
        moveRelative(x - posX, y - posY);
        posX = x;
        posY = y;
    end

    function moveRelative(dx, dy)
        moveMotorRel(mX, dx * kX, Pxy);
        moveMotorRel(mY, dy * kY, Pxy);
    end

    function moveMotorRel(m, deg, power)
        target = m.tachoCount + deg;
        moveMotorTo(m, target, power);
    end

    function moveMotorTo(m, target, power)
        dir = sign(target - m.tachoCount);
        if dir == 0, return; end
        m.power = power * dir;
        m.start();
        while abs(target - m.tachoCount) > 3
            pause(0.01);
        end
        m.stop();
    end

%% ===================== SHAPES ===============================

    function drawSquareSpiral(turns, startStep, inc)
        dir = 0;    % 0=R,1=U,2=L,3=D
        step = startStep;
        penDown();
        for k = 1:turns
            for i = 1:2
                moveDir(dir, step);
                dir = mod(dir+1, 4);
            end
            step = step + inc;
        end
        penUp();
    end

    function drawLissajous(A, B, a, b, delta, steps)
        t = linspace(0, 2*pi, steps);
        x = A*sin(a*t + delta);
        y = B*sin(b*t);
        penDown();
        for i = 2:length(t)
            moveRelative(x(i)-x(i-1), y(i)-y(i-1));
        end
        penUp();
    end

    function moveDir(d, s)
        switch d
            case 0, moveRelative( s, 0);
            case 1, moveRelative( 0, s);
            case 2, moveRelative(-s, 0);
            case 3, moveRelative( 0,-s);
        end
    end

end
