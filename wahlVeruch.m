function ev3_plotter_rwth()
% ==========================================================
% RWTH EV3 2D PLOTTER
% Compatible with RWTH MATLAB EV3 API
%
% - Uses power (NOT speed)
% - Uses tachoCount
% - Uses EV3(), ev3.connect
% - Touch sensor for homing
% ==========================================================

clc; clear;

%% ===================== CONNECTION ============================
ev3 = EV3();
ev3.connect;          % USB by default at RWTH

%% ===================== PORT SETUP ============================
% CHANGE ONLY IF YOUR BUILD IS DIFFERENT
motorX = ev3.motorA;     % X-axis
motorY = ev3.motorB;     % Y-axis
motorP = ev3.motorC;     % Pen motor

touch  = ev3.sensor1;    % Touch sensor

%% ===================== PARAMETERS ============================
powerXY   = 20;     % motor power for X/Y
powerPen  = 15;     % pen motor power

degPerUnitX = 12;   % degrees per grid unit (TUNE)
degPerUnitY = 12;

penUpDeg   = 0;
penDownDeg = 70;

homeDirX = -1;      % flip sign if wrong
homeDirY = -1;

pixelStep = 1;

%% ===================== RESET ================================
motorX.stop(); motorY.stop(); motorP.stop();
motorX.resetTachoCount();
motorY.resetTachoCount();
motorP.resetTachoCount();

posX = 0; posY = 0;

%% ===================== PEN UP ===============================
penUp();

%% ===================== HOMING ===============================
disp("Homing X...");
homeAxis(motorX, touch, powerXY, homeDirX);

disp("Homing Y...");
homeAxis(motorY, touch, powerXY, homeDirY);

motorX.resetTachoCount();
motorY.resetTachoCount();
posX = 0; posY = 0;

disp("Homing complete.");

%% ===================== LOAD IMAGE ===========================
img = imread("test.png");   % SMALL image

if size(img,3) == 4
    img = img(:,:,1:3);
end

img = double(img);
gray = mean(img,3);

% binary image (dark pixels only)
grid = gray < 80;

% downsample (VERY IMPORTANT)
grid = grid(1:4:end, 1:4:end);

[H,W] = size(grid);

%% ===================== DRAW ================================
disp("Drawing...");
moveTo(2,2);

for r = 1:H
    if mod(r,2)==1
        cols = 1:W;
    else
        cols = W:-1:1;
    end

    for c = cols
        x = 2 + (c-1)*pixelStep;
        y = 2 + (r-1)*pixelStep;

        moveTo(x,y);

        if grid(r,c)
            penDown();
            pause(0.03);
            penUp();
        end
    end
end

penUp();
moveTo(0,0);

disp("DONE");

motorX.stop(); motorY.stop(); motorP.stop();

%% ===================== FUNCTIONS =============================
    function penUp()
        moveMotorTo(motorP, penUpDeg, powerPen, 2);
    end

    function penDown()
        moveMotorTo(motorP, penDownDeg, powerPen, 2);
    end

    function moveTo(x,y)
        dx = x - posX;
        dy = y - posY;

        if dx ~= 0
            moveMotorRel(motorX, dx*degPerUnitX, powerXY, 5);
            posX = x;
        end
        if dy ~= 0
            moveMotorRel(motorY, dy*degPerUnitY, powerXY, 5);
            posY = y;
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
        error("Homing failed (touch not pressed)");
    end
    pause(0.01);
end

m.stop();
pause(0.2);
end

function moveMotorRel(m, deg, power, timeout)
startDeg = m.tachoCount;
moveMotorTo(m, startDeg + deg, power, timeout);
end

function moveMotorTo(m, targetDeg, power, timeout)
dir = sign(targetDeg - m.tachoCount);
m.power = power * dir;
m.start();

t0 = tic;
while abs(targetDeg - m.tachoCount) > 3
    if toc(t0) > timeout
        m.stop();
        error("Motor timeout");
    end
    pause(0.01);
end

m.stop();
end
