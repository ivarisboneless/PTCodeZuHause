function draw_square_simple(conn)
% Draws ONE square using EV3 motors
% Only power + tachoCount (no speed control)

if nargin < 1
    conn = 'usb';
end

%% --- CONNECT ---
ev3 = legoev3(conn);

mx = ev3.motorA;   % X axis
my = ev3.motorB;   % Y axis

mx.speedRegulation = 'Off';
my.speedRegulation = 'Off';

mx.brakeMode = 'Coast';
my.brakeMode = 'Coast';

%% --- CALIBRATION ---
% CHANGE THIS after testing
degPerCm = 360;    % motor degrees per 1 cm
side_cm = 4;       % square side length

side_deg = side_cm * degPerCm;

disp("Starting square...");

%% --- DRAW SQUARE ---
% start at (0,0)
resetRotation(mx);
resetRotation(my);

% 1) Right
moveDeg(mx, side_deg, 20);

% 2) Up
moveDeg(my, side_deg, 20);

% 3) Left
moveDeg(mx, -side_deg, 20);

% 4) Down
moveDeg(my, -side_deg, 20);

disp("Square finished.");
end

%% ===== MOTOR MOVE FUNCTION =====
function moveDeg(m, deg, power)
resetRotation(m);

if deg > 0
    m.power = abs(power);
    m.start();
    while readRotation(m) < deg
        pause(0.002);
    end
else
    m.power = -abs(power);
    m.start();
    while readRotation(m) > deg
        pause(0.002);
    end
end

m.stop();
end
