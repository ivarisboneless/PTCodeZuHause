function pix3l_plott3r_demo(connectionType)
% PIX3L PLOTT3R - MATLAB control demo (EV3 Support Package)
%
% What you get:
%   - connect EV3
%   - penUp / penDown
%   - moveTo(x,y) in mm
%   - drawLine, drawSquare, drawCircle
%   - simple calibration knobs (mm per motor degree)
%
% Run:
%   pix3l_plott3r_demo("usb")
%   pix3l_plott3r_demo("bluetooth")

if nargin < 1
    connectionType = "usb";
end

%% ------------------- EDIT ONLY THIS BLOCK --------------------
cfg.conn = lower(string(connectionType));

% Motor ports (CHANGE to match your build)
cfg.portX   = "A";   % X axis motor
cfg.portY   = "B";   % Y axis motor
cfg.portPen = "C";   % Pen up/down motor

% Directions: set to +1 or -1 if an axis moves the opposite way
cfg.dirX = +1;
cfg.dirY = +1;

% Calibration: how many mm of travel for 1 degree motor rotation
% You MUST tune these for your exact mechanics.
cfg.mmPerDegX = 0.10;   % <-- start guess; calibrate
cfg.mmPerDegY = 0.10;   % <-- start guess; calibrate

% Pen angles (tune)
cfg.penUpDeg   = 0;     % pen motor angle for UP
cfg.penDownDeg = 45;    % pen motor angle for DOWN

% Motion
cfg.speedDegPerSec = 200;   % motor speed
cfg.stepMm = 2;             % line stepping for smooth-ish lines
% --------------------------------------------------------------

%% 1) Connect + motors
if cfg.conn == "usb"
    ev3 = legoev3("usb");
else
    ev3 = legoev3("bluetooth");
end

mx = motor(ev3, cfg.portX);
my = motor(ev3, cfg.portY);
mp = motor(ev3, cfg.portPen);

mx.Speed = cfg.speedDegPerSec;
my.Speed = cfg.speedDegPerSec;
mp.Speed = 100;

resetRotation(mx); resetRotation(my); resetRotation(mp);

% Track our own "logical position" (mm) assuming we start at (0,0)
pos = [0, 0];
penIsDown = false;

% Put pen up initially
penUp();

%% 2) Demo drawing (edit freely)
% Draw a square + circle + triangle-ish line pattern

moveTo(10, 10);
penDown();
drawSquare(40);        % 40mm square
penUp();

moveTo(80, 30);
penDown();
drawCircle(20);        % radius 20mm
penUp();

moveTo(20, 80);
penDown();
drawLineTo(60, 120);
drawLineTo(100, 80);
drawLineTo(20, 80);
penUp();

%% 3) Done
disp("Done. Motors stop, EV3 stays connected until function ends.");
stop(mx); stop(my); stop(mp);

%% =============== Nested helper functions =====================

    function penUp()
        mp.Speed = 100;
        movePenTo(cfg.penUpDeg);
        penIsDown = false;
    end

    function penDown()
        mp.Speed = 100;
        movePenTo(cfg.penDownDeg);
        penIsDown = true;
    end

    function movePenTo(targetDeg)
        % Move pen motor to an absolute angle (relative to resetRotation)
        current = readRotation(mp);
        delta = targetDeg - current;
        mp.Speed = sign(delta) * abs(mp.Speed);
        start(mp);
        while abs(readRotation(mp) - targetDeg) > 2
            pause(0.01);
        end
        stop(mp);
    end

    function moveTo(xMm, yMm)
        % Move without drawing unless pen is down (we don't change pen here)
        moveBy(xMm - pos(1), yMm - pos(2));
        pos = [xMm, yMm];
    end

    function moveBy(dxMm, dyMm)
        % Convert mm -> motor degrees and move both axes together
        degX = cfg.dirX * (dxMm / cfg.mmPerDegX);
        degY = cfg.dirY * (dyMm / cfg.mmPerDegY);

        % Move both motors in parallel using relative rotation
        resetRotation(mx); resetRotation(my);

        % Choose motor speed sign to match direction
        mx.Speed = sign(degX) * abs(cfg.speedDegPerSec);
        my.Speed = sign(degY) * abs(cfg.speedDegPerSec);

        start(mx); start(my);

        % Wait until both reach target (simple polling)
        while true
            rx = readRotation(mx);
            ry = readRotation(my);

            doneX = abs(rx) >= abs(degX) - 2;
            doneY = abs(ry) >= abs(degY) - 2;

            if doneX, stop(mx); end
            if doneY, stop(my); end
            if doneX && doneY, break; end

            pause(0.01);
        end
    end

    function drawLineTo(x2, y2)
        % Draw a line from current pos -> (x2,y2) using small steps
        x1 = pos(1); y1 = pos(2);
        dx = x2 - x1; dy = y2 - y1;
        dist = hypot(dx, dy);
        n = max(1, ceil(dist / cfg.stepMm));

        for i = 1:n
            xi = x1 + dx * (i/n);
            yi = y1 + dy * (i/n);
            moveTo(xi, yi);
        end
    end

    function drawSquare(sideMm)
        x0 = pos(1); y0 = pos(2);
        drawLineTo(x0 + sideMm, y0);
        drawLineTo(x0 + sideMm, y0 + sideMm);
        drawLineTo(x0,          y0 + sideMm);
        drawLineTo(x0,          y0);
    end

    function drawCircle(rMm)
        % Approximate circle with polygon steps
        x0 = pos(1); y0 = pos(2);
        steps = 60;
        for k = 1:steps
            th = 2*pi*k/steps;
            xt = x0 + rMm*cos(th);
            yt = y0 + rMm*sin(th);
            if k == 1
                moveTo(xt, yt); % jump to first point
            else
                drawLineTo(xt, yt);
            end
        end
        drawLineTo(x0 + rMm, y0); % close-ish
    end

end
