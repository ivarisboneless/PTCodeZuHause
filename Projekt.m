function ev3_shapes()
% EV3 Plotter (Shapes only) - MATLAB
% X motor = A, Y motor = B, Pen motor = C

%% CONNECT
ev3 = legoev3('usb');         % or legoev3('bluetooth','COMx')
mx  = motor(ev3,'A');         % X axis
my  = motor(ev3,'B');         % Y axis
mp  = motor(ev3,'C');         % Pen

%% SPEEDS (tune)
mx.Speed = 25;
my.Speed = 25;
mp.Speed = 10;

%% CALIBRATION (YOU TUNE THESE)
cfg.degPerMmX = 8.0;          % degrees motor rotation per 1 mm X movement
cfg.degPerMmY = 8.0;          % degrees motor rotation per 1 mm Y movement
cfg.penUpDeg   = -80;         % pen up angle
cfg.penDownDeg =  80;         % pen down angle

%% START STATE (treat current position as (0,0))
state.x = 0;  state.y = 0;
resetRotation(mx); resetRotation(my); resetRotation(mp);

penUp(mp,cfg);

%% ----------- DRAW SHAPES -----------
% Move to a safe start location
state = moveTo(mx,my,cfg,state, 10, 10);

% 1) Square: top-left at (10,10), side 40mm
state = drawSquare(mx,my,mp,cfg,state, 10,10, 40);

% 2) Triangle: base-left at (70,10), side 40mm
state = drawTriangle(mx,my,mp,cfg,state, 70,10, 40);

% 3) Circle: center (30,80), radius 20mm, 60 points
state = drawCircle(mx,my,mp,cfg,state, 30,80, 20, 60);

penUp(mp,cfg);
disp("Done.");
end

%% ================== PEN ==================
function penUp(mp,cfg),  movePen(mp,cfg.penUpDeg);   end
function penDown(mp,cfg),movePen(mp,cfg.penDownDeg); end

function movePen(mp, targetDeg)
resetRotation(mp);

% choose direction by speed sign
base = abs(mp.Speed);
if targetDeg < 0
    mp.Speed = -base;
else
    mp.Speed = base;
end

start(mp);
while abs(readRotation(mp)) < abs(targetDeg)
    pause(0.01);
end
stop(mp);
end

%% ================== MOVE X/Y ==================
function state = moveTo(mx,my,cfg,state, x_mm, y_mm)
dx = x_mm - state.x;
dy = y_mm - state.y;

degX = dx * cfg.degPerMmX;
degY = dy * cfg.degPerMmY;

resetRotation(mx); resetRotation(my);

% motor directions via speed sign
mx.Speed = sign(degX) * abs(mx.Speed);
my.Speed = sign(degY) * abs(my.Speed);

start(mx); start(my);

while abs(readRotation(mx)) < abs(degX) || abs(readRotation(my)) < abs(degY)
    pause(0.01);
end

stop(mx); stop(my);

state.x = x_mm;
state.y = y_mm;
end

%% ================== DRAW PRIMITIVES ==================
function state = drawPolyline(mx,my,mp,cfg,state, pts)
% pts = Nx2 [x y] in mm, draws connected lines
state = moveTo(mx,my,cfg,state, pts(1,1), pts(1,2));
penDown(mp,cfg);

for k = 2:size(pts,1)
    state = moveTo(mx,my,cfg,state, pts(k,1), pts(k,2));
end

penUp(mp,cfg);
end

function state = drawSquare(mx,my,mp,cfg,state, x0,y0, side)
pts = [
    x0      y0
    x0+side y0
    x0+side y0+side
    x0      y0+side
    x0      y0
];
state = drawPolyline(mx,my,mp,cfg,state, pts);
end

function state = drawTriangle(mx,my,mp,cfg,state, x0,y0, side)
% approx equilateral
pts = [
    x0           y0
    x0+side      y0
    x0+side/2    y0 + side*0.866
    x0           y0
];
state = drawPolyline(mx,my,mp,cfg,state, pts);
end

function state = drawCircle(mx,my,mp,cfg,state, cx,cy, r, nPts)
t = linspace(0, 2*pi, nPts+1);
pts = [cx + r*cos(t(:)), cy + r*sin(t(:))];
state = drawPolyline(mx,my,mp,cfg,state, pts);
end
