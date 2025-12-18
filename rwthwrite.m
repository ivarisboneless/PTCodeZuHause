function rwthwrite()
% ==================================================


clc; clear;

ev3 = EV3();
ev3.connect('usb')

%% ---------- PORTS ----------
mX = ev3.motorA;       % X axis
mY = ev3.motorC;       % Y axis
touch = ev3.sensor2;   % touch sensor (X home)

%% ---------- PARAMETERS ----------
Pmove = 25;
Phome = 12;

kX = -9;               % deg per unit (X)  <-- negative!
kY =  8;               % deg per unit (Y)

letterW = 6;           % units
letterH = 10;          % units
gap     = 3;           % units

tolDeg = 12;           % degrees tolerance

%Motoren Stoppen!
cleanup = onCleanup(@()stopAll(mX,mY));

% initialization 
stopAll(mX,mY);
mX.resetTachoCount();
mY.resetTachoCount();

mX.power = -Phome;
mX.start();
while touch.value == 0
    pause(0.01);
end
mX.stop();
pause(0.2);
mX.resetTachoCount();

%entfernen von Sensor
moveRel(4, 4);     % kann auch erhört sein

%schreiben!
drawR();  moveRel(letterW + gap, 0);
drawW();  moveRel(letterW + gap, 0);
drawT();  moveRel(letterW + gap, 0);
drawH();

stopAll(mX,mY);
disp("DONE: RWTH written.");
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

function moveRel(dxU, dyU)
    % X move
    if dxU ~= 0
      targetX = mX.tachoCount + dxU * kX;
      moveMotorToTacho(mX, targetX, Pmove, tolDeg);
    end

    % Y move
    if dyU ~= 0
        targetY = mY.tachoCount + dyU * kY;
        moveMotorToTacho(mY, targetY, Pmove, tolDeg);
    end
  end

end


function stopAll(mX,mY)
try, mX.stop(); end
try, mY.stop(); end
end

function moveMotorToTacho(m, targetDeg, power, tolDeg)
% Move motor until it reaches targetDeg (within tolDeg) with timeout.

startDeg = m.tachoCount;
dist = abs(targetDeg - startDeg);
if dist < tolDeg
    return;
end

% Direction MUST be based on target-current
dir = sign(targetDeg - startDeg);
m.power = power * dir;
m.start();

t0 = tic;
timeout = max(2.0, 0.03*dist + 1.0);   % adaptive timeout

while abs(targetDeg - m.tachoCount) > tolDeg
    if toc(t0) > timeout
        m.stop();
        error("Timeout: motor didn't reach target. (Check jam / power / direction)");
    end
    pause(0.01);
end

m.stop();
end
