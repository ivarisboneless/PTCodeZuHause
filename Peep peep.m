function myUserData = lightReadWithTimer_simple(conn, duration_s)
% Minimal timer-based light sensor read (keeps readLightTimerFcn name)

if nargin < 1, conn = 'usb'; end
if nargin < 2, duration_s = 7; end

% Period requirement: USB=50ms, Bluetooth=100ms
period = 0.05;
if strcmpi(conn,'bluetooth') || strcmpi(conn,'bt')
    period = 0.10;
end

% Connect EV3
ev3 = legoev3(conn);

% Sensor (change sensor1 -> sensor2/3/4 if needed)
light = ev3.sensor1;

% Pack everything into myUserData (timer can only access this)
myUserData.light    = light;
myUserData.times    = [];
myUserData.values   = [];
myUserData.t0       = tic;        % start time
myUserData.duration = duration_s; % stop after this many seconds

% Create timer
T = timer( ...
    'Period', period, ...
    'ExecutionMode', 'fixedRate', ...
    'UserData', myUserData, ...
    'TimerFcn', @readLightTimerFcn );

% Start + wait until done
start(T);
wait(T);

% Read final results back
myUserData = T.UserData;

% Cleanup
delete(T);

% Plot
figure; grid on;
plot(myUserData.times, myUserData.values, '-');
xlabel('t [s]'); ylabel('light value');
title(sprintf('Light with timer (%s, %.0f ms)', lower(conn), 1000*period));

end


function readLightTimerFcn(T, ~)
% This function runs automatically every "Period" seconds

myUserData = T.UserData;

t = toc(myUserData.t0);

% Stop condition (replaces while toc < duration)
if t >= myUserData.duration
    stop(T);
    T.UserData = myUserData;
    return;
end

% Read sensor once
v = myUserData.light.value;

% Store
myUserData.times(end+1)  = t;
myUserData.values(end+1) = v;

% Save back into timer
T.UserData = myUserData;

end
