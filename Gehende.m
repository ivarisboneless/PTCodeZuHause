function draw_square_ev3(conn)
% Draw a simple square using EV3 plotter
% Uses ONLY power + tachoCount (NO speed control)

if nargin < 1
    conn = 'usb';
end

%% -------- CONFIG (EDIT IF NEEDED) --------
xPort = 'A';        % X axis motor
yPort = 'B';        % Y axis motor
touchPort = 1;      % touch sensor input

movePower = 40;     % increase if motors don't move
side_cm = 4;        % square size

degPerCmX = 360;    % CALIBRATE later
degPerCmY = 360;    % CALIBRATE later
%% ----------------------------------------

%% Connect
ev3 = legoev3(conn);

mx = ev3.(['motor' xPort]);
my = ev3.(['motor' yPort]);
ts = ev3.(['sensor' num2str(touchPort)]);

setupMotor(mx);
setupMotor(my);

disp("EV3 connected");

%% Home Y axis using touch sensor
disp("Homing Y axis...");
homeWithTouch(my, ts);

%% Draw square
dx = side_cm * degPerCmX;
dy = side_cm * degPerCmY;

moveDeg(mx,  dx, movePower);   % right
moveDeg(my,  dy, movePower);   % up
moveDeg(mx, -dx, movePower);   % left
moveDeg(my, -dy, movePower);   % down

disp("Square drawn.");
end

%% ========== Helper functions ==========

function setupMotor(m)
m.speedRegulation = 'Off';
m.brakeMode = 'Brake';
m.power = 0;
end

function moveDeg(m, targetDeg, power)
resetTachoCount(m);

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

function homeWithTouch(m, ts)
m.brakeMode = 'Brake';
m.speedRegulation = 'Off';

% fast approach
m.power = 30;
m.start();
while ts.value == 0
    pause(0.001);
end
m.stop();

% back off
resetTachoCount(m);
m.power = -30;
m.start();
while readTachoCount(m) > -120
    pause(0.001);
end
m.stop();

% slow approach
m.power = 10;
m.start();
while ts.value == 0
    pause(0.001);
end
m.stop();

resetTachoCount(m);   % THIS IS HOME = 0
end
