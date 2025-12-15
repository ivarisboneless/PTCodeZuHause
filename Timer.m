function myUserData = lightReadWithTimer(connectionType, duration_s)
% ============================================================
% Versuch 3.2 – Timersteuerung (EV3 Light Sensor)
% Replaces while-loop polling with a MATLAB timer.
%
% Usage examples:
%   data = lightReadWithTimer('usb', 7);
%   data = lightReadWithTimer('bluetooth', 7);
%
% Output:
%   myUserData.values   - measured light values
%   myUserData.times    - time stamps (s) since start
%   myUserData.period   - timer period used
%   myUserData.execMode - execution mode used
% ============================================================

    if nargin < 1 || isempty(connectionType), connectionType = 'usb'; end
    if nargin < 2 || isempty(duration_s),     duration_s     = 7;      end

    %% ------------------- Settings ----------------------------
    % Adjust ports if your setup differs
    lightPort = 1;  % EV3 sensor port (1..4). Change if needed.

    % Period requirement from sheet:
    %  - Bluetooth: 100 ms
    %  - USB:       50 ms
    switch lower(connectionType)
        case {'bluetooth','bt'}
            period_s = 0.10;
        otherwise
            period_s = 0.05;
    end

    execMode = 'fixedRate';   % try 'fixedDelay' later for part (e)

    %% ------------------- Connect EV3 -------------------------
    if any(strcmpi(connectionType, {'bluetooth','bt'}))
        % If your MATLAB requires a specific EV3 name/address for BT,
        % use: legoev3('bluetooth','EV3_NAME') or similar.
        % Many setups still work with just:
        ev3 = legoev3('bluetooth');
    else
        ev3 = legoev3('usb');
    end

    % Light sensor object (mode depends on your toolbox/sensor type)
    light = ev3.(['sensor' num2str(lightPort)]);
    try
        % Common for EV3 color sensor as reflected light:
        light.mode = 'reflected';
    catch
        % If mode name differs in your toolbox, ignore and use default
    end

    %% ------------------- myUserData struct -------------------
    myUserData = struct();
    myUserData.ev3      = ev3;
    myUserData.light    = light;
    myUserData.values   = [];     % sensor values
    myUserData.times    = [];     % timestamps
    myUserData.period   = period_s;
    myUserData.execMode = execMode;
    myUserData.duration = duration_s;
    myUserData.tStart   = [];     % will store tic handle
    myUserData.nMax     = ceil(duration_s/period_s) + 20; % prealloc cushion
    myUserData.idx      = 0;

    % Preallocate (helps timing stability)
    myUserData.values = nan(1, myUserData.nMax);
    myUserData.times  = nan(1, myUserData.nMax);

    %% ------------------- Create timer ------------------------
    T = timer( ...
        'ExecutionMode', execMode, ...
        'Period',        period_s, ...
        'BusyMode',      'drop', ...            % if a tick is late, drop it
        'UserData',      myUserData, ...
        'TimerFcn',      @readLightTimerFcn, ...
        'StopFcn',       @stopLightTimerFcn);

    %% ------------------- Start measurement -------------------
    myUserData = T.UserData;
    myUserData.tStart = tic;         % start stopwatch
    T.UserData = myUserData;

    fprintf('Starting timer: Period=%.3fs, Mode=%s, Duration=%.2fs\n', ...
        period_s, execMode, duration_s);

    start(T);

    % Wait until timer stops (so function returns only when done)
    wait(T);

    % Get final data back out
    myUserData = T.UserData;

    % Trim preallocated NaNs
    n = myUserData.idx;
    myUserData.values = myUserData.values(1:n);
    myUserData.times  = myUserData.times(1:n);

    % Cleanup timer object
    delete(T);

    %% ------------------- Plot -------------------------------
    figure; grid on; hold on;
    plot(myUserData.times, myUserData.values, '-');
    xlabel('Time [s]');
    ylabel('Light value');
    title(sprintf('Light readings with timer (%s, Period=%.0f ms)', ...
        lower(connectionType), 1000*period_s));

end

%% ============================================================
%% Timer callback: runs every Period seconds
%% ============================================================
function readLightTimerFcn(T, ~)
    myUserData = T.UserData;                 % 1) take the backpack

    % stop condition
    tNow = toc(myUserData.tStart);
    if tNow >= myUserData.duration
        stop(T);
        return;
    end

    % Read sensor value (toolbox may expose value differently)
    try
        v = myUserData.light.value;
    catch
        % Some setups use readValue()
        v = readValue(myUserData.light);
    end

    % Store
    myUserData.idx = myUserData.idx + 1;
    k = myUserData.idx;

    if k > numel(myUserData.values)
        % grow if needed (rare)
        myUserData.values(end+100) = nan;
        myUserData.times(end+100)  = nan;
    end

    myUserData.values(k) = v;
    myUserData.times(k)  = tNow;

    T.UserData = myUserData;                 % 2) put backpack back
end

%% ============================================================
%% Stop callback: called once when timer stops
%% ============================================================
function stopLightTimerFcn(T, ~)
    myUserData = T.UserData;
    fprintf('Timer stopped. Samples collected: %d\n', myUserData.idx);
    T.UserData = myUserData;
end
