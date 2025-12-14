function lightGui(connectionType)
% lightGui("usb") or lightGui("bluetooth")
% Full solution: connect EV3, read light sensor (ambient/reflect),
% timer-based acquisition, live plot, Start/Stop/Toggle Mode, clean shutdown.

if nargin < 1
    connectionType = "usb";
end

% ---------- CONFIG ----------
cfg.connectionType = lower(string(connectionType)); % "usb" or "bluetooth"
cfg.sensorPort     = 3;        % change if your sensor is on another input port
cfg.sensorMode     = "ambient";% start mode: "ambient" or "reflect"
cfg.periodUSB      = 0.05;     % 50 ms
cfg.periodBT       = 0.10;     % 100 ms
cfg.bufferLen      = 200;      % points shown in plot

% choose timer period based on connection
if cfg.connectionType == "bluetooth"
    cfg.period = cfg.periodBT;
else
    cfg.period = cfg.periodUSB;
end

% ---------- STATE ----------
S = struct();
S.cfg    = cfg;
S.brick  = [];
S.sensor = [];
S.timer  = [];
S.t0     = [];
S.times  = zeros(1, cfg.bufferLen);
S.values = zeros(1, cfg.bufferLen);

% ---------- UI ----------
ui = struct();

ui.fig = uifigure("Name","EV3 Light Sensor GUI","Position",[200 200 900 520]);
ui.fig.CloseRequestFcn = @onClose;

ui.ax = uiaxes(ui.fig, "Position",[40 90 820 400]);
grid(ui.ax,"on");
xlabel(ui.ax,"Time [s]");
ylabel(ui.ax,"Light intensity");
title(ui.ax,"Live Light Sensor");
ui.line = plot(ui.ax, S.times, S.values);
ui.ax.XLimMode = "auto";

ui.startBtn  = uibutton(ui.fig, "Text","Start",  "Position",[40 30 120 40], ...
    "ButtonPushedFcn", @onStart);

ui.stopBtn   = uibutton(ui.fig, "Text","Stop",   "Position",[180 30 120 40], ...
    "ButtonPushedFcn", @onStop);

ui.toggleBtn = uibutton(ui.fig, "Text","Toggle Mode", "Position",[320 30 140 40], ...
    "ButtonPushedFcn", @onToggleMode);

ui.modeLbl = uilabel(ui.fig, "Text","Mode:", "Position",[500 38 50 22]);
ui.modeTxt = uilabel(ui.fig, "Text", char(S.cfg.sensorMode), "Position",[550 38 120 22]);

ui.statusLbl = uilabel(ui.fig, "Text","Status:", "Position",[700 38 60 22]);
ui.statusTxt = uilabel(ui.fig, "Text","Connecting...", "Position",[760 38 120 22]);

drawnow;

% ---------- CONNECT + TIMER SETUP ----------
try
    [S.brick, S.sensor] = connectEV3AndSensor(S.cfg.connectionType, S.cfg.sensorPort);
    setSensorMode(S.sensor, S.cfg.sensorMode);
    ui.statusTxt.Text = "Connected";
catch ME
    ui.statusTxt.Text = "Connect failed";
    uialert(ui.fig, ME.message, "EV3 Error");
    return;
end

S.t0 = tic;

S.timer = timer( ...
    "ExecutionMode","fixedRate", ...
    "Period", S.cfg.period, ...
    "TimerFcn", @onTimerTick);

% store everything in figure UserData so callbacks can access/update
ui.fig.UserData = struct("S",S,"ui",ui);

% ============== CALLBACKS ==============

function onStart(~,~)
    D = ui.fig.UserData;
    if isempty(D.S.timer) || ~isvalid(D.S.timer)
        return;
    end
    if strcmp(D.S.timer.Running,"off")
        start(D.S.timer);
        D.ui.statusTxt.Text = "Running";
    end
    ui.fig.UserData = D;
end

function onStop(~,~)
    D = ui.fig.UserData;
    if isempty(D.S.timer) || ~isvalid(D.S.timer)
        return;
    end
    if strcmp(D.S.timer.Running,"on")
        stop(D.S.timer);
        D.ui.statusTxt.Text = "Stopped";
    end
    ui.fig.UserData = D;
end

function onToggleMode(~,~)
    D = ui.fig.UserData;

    % stop safely
    if ~isempty(D.S.timer) && isvalid(D.S.timer) && strcmp(D.S.timer.Running,"on")
        stop(D.S.timer);
    end

    % toggle mode
    if D.S.cfg.sensorMode == "ambient"
        D.S.cfg.sensorMode = "reflect";
    else
        D.S.cfg.sensorMode = "ambient";
    end

    % apply mode to sensor
    try
        setSensorMode(D.S.sensor, D.S.cfg.sensorMode);
        D.ui.modeTxt.Text = char(D.S.cfg.sensorMode);
        D.ui.statusTxt.Text = "Mode changed";
    catch ME
        D.ui.statusTxt.Text = "Mode error";
        uialert(D.ui.fig, ME.message, "Sensor Mode Error");
    end

    % resume if it was running? (optional)
    % start(D.S.timer);

    ui.fig.UserData = D;
end

function onTimerTick(tObj, ~)
    if ~isvalid(ui.fig)
        return;
    end

    D = ui.fig.UserData;

    % read value
    try
        val = readLightIntensity(D.S.sensor);
    catch
        % if EV3 disconnects mid-run, stop timer
        try stop(tObj); end %#ok<TRYNC>
        D.ui.statusTxt.Text = "Read failed";
        ui.fig.UserData = D;
        return;
    end

    t = toc(D.S.t0);

    % shift buffer left and append new sample
    D.S.times(1:end-1)  = D.S.times(2:end);
    D.S.values(1:end-1) = D.S.values(2:end);
    D.S.times(end)  = t;
    D.S.values(end) = val;

    % update plot
    set(D.ui.line, "XData", D.S.times, "YData", D.S.values);
    drawnow limitrate;

    ui.fig.UserData = D;
end

function onClose(~,~)
    % graceful cleanup
    if ~isvalid(ui.fig)
        return;
    end

    D = ui.fig.UserData;

    % stop + delete timer
    try
        if ~isempty(D.S.timer) && isvalid(D.S.timer)
            stop(D.S.timer);
            delete(D.S.timer);
        end
    catch
    end

    % disconnect EV3 (best-effort)
    try
        disconnectEV3(D.S.brick);
    catch
    end

    delete(ui.fig);
end

end % end main function

% ============== HELPERS (same file) ==============

function [brickObj, sensorObj] = connectEV3AndSensor(connectionType, sensorPort)
% connectionType: "usb" or "bluetooth"
brickObj = legoev3(connectionType);
sensorObj = colorSensor(brickObj, sensorPort);
end

function setSensorMode(sensorObj, modeStr)
% modeStr: "ambient" or "reflect"
modeStr = lower(string(modeStr));
switch modeStr
    case "ambient"
        sensorObj.Mode = "AmbientLight";
    case "reflect"
        sensorObj.Mode = "ReflectedLight";
    otherwise
        error("Unknown mode. Use 'ambient' or 'reflect'.");
end
end

function disconnectEV3(brickObj)
% Best-effort disconnect (MATLAB releases object)
clear brickObj;
end
