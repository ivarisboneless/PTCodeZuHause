function plotter_square_safe(conn)
% EV3 plotter: SAFE homing + square
% - prevents slamming into touch sensor
% - 2-stage homing: fast -> backoff -> super slow
% - tacho safety limit

if nargin < 1
    conn = 'usb';
end

%% ============ CONFIG (EDIT THESE ONLY) ============
cfg.xPort = 'A';
cfg.yPort = 'B';          % axis that hits the touch sensor
cfg.penPort = 'C';
cfg.touchPort = 1;

cfg.movePower = 40;

% Homing powers (make these SMALL to avoid pain)
cfg.homeFast = 15;        % was 25 → too aggressive for your build
cfg.homeSlow = 4;         % super gentle final touch
cfg.backoffDeg = 220;     % ensure switch fully releases
cfg.releaseDeg = 60;

% Safety: maximum degrees allowed during homing before abort
cfg.homeMaxDeg = 900;     % adjust if your axis needs more travel

% Paper handling
cfg.paperOffsetDeg = 250;

% Square
cfg.squareSide_cm = 4;
cfg.degPerCmX = 360;
cfg.degPerCmY = 360;

% Pen
cfg.penPower = 15;
cfg.penDownDeg = 80;
cfg.penUpDeg   = -80;
%% =================================================

ev3 = legoev3(conn);

mx = ev3.(['motor' cfg.xPort]);
my = ev3.(['motor' cfg.yPort]);
mp = ev3.(['motor' cfg.penPort]);
ts = ev3.(['sensor' num2str(cfg.touchPort)]);

setupMotor(mx); setupMotor(my); setupMotor(mp);

disp("EV3 connected.");
disp("Insert + align paper now.");
pause(2);

%% SAFE HOME (Y axis)
disp("SAFE homing Y...");
homeWithTouchSafe(my, ts, cfg);

resetTachoCount(mx);          % no switch on X, define as 0

%% Move paper to start zone
moveDeg(my, cfg.paperOffsetDeg, cfg.movePower);

%% Draw square
penUp(mp, cfg);

dx = cfg.squareSide_cm * cfg.degPerCmX;
dy = cfg.squareSide_cm * cfg.degPerCmY;

penDown(mp, cfg);

moveDeg(mx,  dx, cfg.movePower);
moveDeg(my,  dy, cfg.movePower);
moveDeg(mx, -dx, cfg.movePower);
moveDeg(my, -dy, cfg.movePower);

penUp(mp, cfg);

disp("Done.");
end

%% ================= HELPERS =================

function setupMotor(m)
m.speedRegulation = 'Off';
m.brakeMode = 'Brake';
m.power = 0;
end

function moveDeg(m, targetDeg, power)
resetTachoCount(m);
m.brakeMode = 'Brake';

if targetDeg >= 0
    m.power = abs(power);
    m.start();
    while readTachoCount(m) < targetDeg
        pause(0.001);
    end
else
    m.power = -abs(power);
    m.start();
    while readTachoCount(m) > targetDeg
        pause(0.001);
    end
end
m.stop();
end

function homeWithTouchSafe(m, ts, cfg)
m.brakeMode = 'Brake';
m.speedRegulation = 'Off';

% --- FAST approach (gentle) ---
resetTachoCount(m);
m.power = cfg.homeFast;
m.start();

while ts.value == 0
    if readTachoCount(m) > cfg.homeMaxDeg
        m.stop();
        error("Homing safety abort: exceeded cfg.homeMaxDeg (wrong direction / no switch).");
    end
    pause(0.001);
end
m.stop();                 % stop immediately when touched

% --- BACKOFF so switch releases ---
moveDeg(m, -cfg.backoffDeg, cfg.homeFast);

% --- SUPER SLOW approach for accurate 0 ---
resetTachoCount(m);
m.power = cfg.homeSlow;
m.start();

while ts.value == 0
    if readTachoCount(m) > cfg.homeMaxDeg
        m.stop();
        error("Homing slow safety abort.");
    end
    pause(0.001);
end
m.stop();

% release a bit so it isn't pressing hard
moveDeg(m, -cfg.releaseDeg, cfg.homeFast);

resetTachoCount(m);       % HOME = 0 here
end

function penDown(mp, cfg)
moveDeg(mp, cfg.penDownDeg, cfg.penPower);
end

function penUp(mp, cfg)
moveDeg(mp, cfg.penUpDeg, cfg.penPower);
end
