function light_gui_easy()
% One-file GUI: Start / Stop / Toggle Mode + live plot

    % ====== settings (edit only these) ======
    connectionType = 'usb';   % 'usb' or 'bluetooth'
    mode = 'ambient';         % 'ambient' or 'reflect'
    period = 0.10;            % seconds (bluetooth: try 0.2)
    bufferN = 200;            % points shown on plot
    sensorPort = 1;           % change if needed (1..4)
    % =======================================

    % 1) connect once
    if strcmpi(connectionType,'usb')
        ev3 = legoev3('usb');
    else
        ev3 = legoev3('bluetooth');
    end
    sensor = colorSensor(ev3, sensorPort);

    % 2) make GUI
    fig = uifigure('Name','EV3 Light Easy','Position',[100 100 800 450]);
    ax  = uiaxes(fig,'Position',[60 90 700 320]);
    grid(ax,'on'); hold(ax,'on');

    lineH = plot(ax, nan(bufferN,1), nan(bufferN,1), 'LineWidth', 1.5);
    xlabel(ax,'time since first shown [s]');
    ylabel(ax,['light ' mode]);

    txt = uilabel(fig,'Position',[60 50 250 22],'Text',['Mode: ' mode]);

    btnStart = uibutton(fig,'Position',[350 40 100 35],'Text','Start');
    btnStop  = uibutton(fig,'Position',[460 40 100 35],'Text','Stop');
    btnMode  = uibutton(fig,'Position',[570 40 150 35],'Text','Toggle Mode');

    % 3) data for timer
    data.sensor  = sensor;
    data.mode    = mode;
    data.t0      = tic;
    data.t       = nan(bufferN,1);
    data.y       = nan(bufferN,1);
    data.lineH   = lineH;
    data.ax      = ax;
    data.txt     = txt;

    % 4) create timer
    tim = timer;
    tim.ExecutionMode = 'fixedRate';
    tim.Period = period;
    tim.BusyMode = 'drop';
    tim.UserData = data;
    tim.TimerFcn = @onTick;

    % 5) button callbacks
    btnStart.ButtonPushedFcn = @(~,~)startTimer();
    btnStop.ButtonPushedFcn  = @(~,~)stopTimer();
    btnMode.ButtonPushedFcn  = @(~,~)toggleMode();

    % 6) close cleanup
    fig.CloseRequestFcn = @(~,~)closeApp();

    % ====== nested functions ======

    function startTimer()
        if strcmp(tim.Running,'off')
            d = tim.UserData;
            d.t0 = tic;
            d.t(:) = nan; 
            d.y(:) = nan;
            tim.UserData = d;
            start(tim);
        end
    end

    function stopTimer()
        if strcmp(tim.Running,'on')
            stop(tim);
        end
    end

    function toggleMode()
        wasRunning = strcmp(tim.Running,'on');
        if wasRunning
            stop(tim);
        end

        d = tim.UserData;

        if strcmp(d.mode,'ambient')
            d.mode = 'reflect';
        else
            d.mode = 'ambient';
        end

        d.txt.Text = ['Mode: ' d.mode];
        ylabel(d.ax, ['light ' d.mode]);

        tim.UserData = d;

        if wasRunning
            start(tim);
        end
    end

    function closeApp()
        if strcmp(tim.Running,'on')
            stop(tim);
        end
        delete(tim);
        clear sensor ev3
        delete(fig);
    end

end

% ====== Timer callback (must be outside) ======
function onTick(tim, ~)

    d = tim.UserData;

    % read value
    tNow = toc(d.t0);
    yNow = readLightIntensity(d.sensor, d.mode);

    % shift left + append
    d.t(1:end-1) = d.t(2:end);
    d.y(1:end-1) = d.y(2:end);
    d.t(end) = tNow;
    d.y(end) = yNow;

    % find first valid time (to avoid NaN - NaN)
    idx = find(~isnan(d.t), 1, 'first');
    if isempty(idx)
        x = d.t;
    else
        x = d.t - d.t(idx);
    end

    % update plot
    if isvalid(d.lineH)
        set(d.lineH, 'XData', x, 'YData', d.y);
        drawnow limitrate;
    end

    tim.UserData = d;
end
