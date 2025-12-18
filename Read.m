function rwth_write_RWTH_FIXED()
% ==================================================
% RWTH EV3 Plotter – WRITE "RWTH" (FIXED VERSION)
% Key fix: move away from touch sensor after homing
% ==================================================

clc; clear;

%% ---------- CONNECT ----------
ev3 = EV3();
ev3.connect;

%% ---------- PORTS ----------
mX = ev3.motorA;      % X axis
mY = ev3.motorB;      % Y axis
touch = ev3.sensor1;  % touch sensor (X home)

%% ---------- PARAMETERS ----------
Pmove = 25;
Phome = 12;

kX = -9;              % deg per unit
kY =  8;

letterW = 6;          % letter width (units)
letterH = 10;         % letter height
gap     = 3;          % space between letters

%% ---------- INIT ----------
mX.stop(); mY.stop();
mX.resetTachoCount();
mY.resetTachoCount();

posX = 0;
posY = 0;

%% ---------- HOME X (RWTH STYLE) ----------
mX.power = -Phome;
mX.start();

while touch.value == 0
    pause(0.01);
end

mX.stop();
pause(0.2);
mX.resetTachoCount();

%% ---------- IMPORTANT FIX -----------------
% Move AWAY from touch sensor into drawing area
moveRel(3, 3);     % <-- THIS PREVENTS SENSOR COLLISION

%% ---------- WRITE R ----------
drawR();
moveRel(letterW + gap, 0);

%% ---------- WRITE W ----------
drawW();
moveRel(letterW + gap, 0);

%% ---------- WRITE T ----------
drawT();
moveRel(letterW + gap, 0);

%% ---------- WRITE H ----------
drawH();

%% ---------- DONE ----------
mX.stop(); mY.stop();
disp("RWTH written safely.");

%% ==================================================
%% =============== LETTER FUNCTIONS =================
%% ==================================================

    function drawR()
        moveRel(0, letterH);
        moveRel(letterW, 0);
        moveRel(0, -letterH/2);
        moveRel(-letterW, 0);
        moveRel(letterW, -letterH/2);
    end

    function drawW()
        moveRel(0, letterH);
        moveRel(letterW/2, -letterH);
        moveRel(letterW/2, letterH);
        moveRel(0, -letterH);
    end

    function drawT()
        moveRel(letterW, 0);
        moveRel(-letterW/2, 0);
        moveRel(0, letterH);
    end

    function drawH()
        moveRel(0, letterH);
        moveRel(0, -letterH/2);
        moveRel(letterW, 0);
        moveRel(0, letterH/2);
        moveRel(0, -letterH);
    end

%% ==================================================
%% =============== MOVE FUNCTION ====================
%% ==================================================

    function moveRel(dxU, dyU)

        % ---- X movement ----
        if dxU ~= 0
            targetX = mX.tachoCount + dxU * kX;
            mX.power = Pmove * sign(dxU);
            mX.start();
            while abs(targetX - mX.tachoCount) > 10
                pause(0.01);
            end
            mX.stop();
        end

        % ---- Y movement ----
        if dyU ~= 0
            targetY = mY.tachoCount + dyU * kY;
            mY.power = Pmove * sign(dyU);
            mY.start();
            while abs(targetY - mY.tachoCount) > 10
                pause(0.01);
            end
            mY.stop();
        end

        posX = posX + dxU;
        posY = posY + dyU;
    end

end
