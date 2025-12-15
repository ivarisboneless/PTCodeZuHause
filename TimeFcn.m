function data = lightReadWithTimer_simple(conn, duration_s)
% Minimal timer-based light sensor read (robust + visible points)

if nargin < 1, conn = 'usb'; end
if nargin < 2, duration_s = 7; end

% Period: USB=50ms, Bluetooth=100ms
period = 0.05;
if strcmpi(conn,'bluetooth') || strcmpi(conn,'bt')
    period = 0.10;
end

% Connect EV3
ev3 = legoev3(conn);

% Light sensor (change port if needed)
light = ev3.sensor1;

% Prepare storage + timing
data.light    = light;
data.times    = [];
data.values   = [];
data.duration = duration_s;
data.t0       = [];           % set at start

% Force a fixed number of timer executions
nTicks = ceil(duration_s/period) + 1;

T = timer( ...
    'Period', period, ...
    'ExecutionMode', 'fixedRate', ...
    'TasksToExecute', nTicks, ...
    'UserData', data, ...
    'TimerFcn', @readLightTimerFcn );

% Start timing RIGHT BEFORE starting timer
data = T.UserData;
data.t0 = tic;
T.UserData = data;

start(T);
wait(T);

data = T.UserData;
delete(T);

% Plot with markers so points are visible
figure; grid on;
plot(data.times, data.values, '.-');
xlabel('t [s]'); ylabel('light value');
title(sprintf('Light with timer (%s, %.0f ms)', lower(conn), 1000*period));

% Quick sanity print
fprintf("Collected %d samples.\n", numel(data.times));
end


function readLightTimerFcn(T, ~)
data = T.UserData;

% If t0 somehow missing, set it (failsafe)
if isempty(data.t0)
    data.t0 = tic;
end

t = toc(data.t0);

% Read sensor safely
try
    v = data.light.value;
catch
    v = NaN;   % if read fails, store NaN so you SEE something happened
end

% Store one sample
data.times(end+1)  = t;
data.values(end+1) = v;

T.UserData = data;
end
