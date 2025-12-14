
%% f = uifigure;
%% g = lightGui(f);
classdef lightGui < matlab.ui.componentcontainer.ComponentContainer

    % ========= UI =========
    properties (Access = private)
        StartButton matlab.ui.control.Button
        StopButton  matlab.ui.control.Button
        ToggleButton matlab.ui.control.Button
        ModeLabel matlab.ui.control.Label
        Ax matlab.ui.control.UIAxes
    end

    % ========= DATA =========
    properties (Access = private)
        brick
        sensor
        myTimer
        sensorMode = "ambient"
        t0
        time = []
        values = []
    end

    methods (Access = protected)

        function setup(app)

            app.Position = [100 100 500 350];

            app.Ax = uiaxes(app, ...
                'Position',[50 100 400 200]);
            grid(app.Ax,'on');
            xlabel(app.Ax,'Time [s]');
            ylabel(app.Ax,'Light');

            app.StartButton = uibutton(app, ...
                'Text','Start', ...
                'Position',[50 40 100 30], ...
                'ButtonPushedFcn', @(~,~)startMeasurement(app));

            app.StopButton = uibutton(app, ...
                'Text','Stop', ...
                'Position',[200 40 100 30], ...
                'ButtonPushedFcn', @(~,~)stopMeasurement(app));

            app.ToggleButton = uibutton(app, ...
                'Text','Toggle Mode', ...
                'Position',[350 40 100 30], ...
                'ButtonPushedFcn', @(~,~)toggleMode(app));

            app.ModeLabel = uilabel(app, ...
                'Text','Mode: ambient', ...
                'Position',[50 10 200 20]);

            % connect EV3
            app.brick = legoev3('usb');
            app.sensor = colorSensor(app.brick,3);
            app.sensor.Mode = 'AmbientLight';

            % timer
            app.myTimer = timer( ...
                'ExecutionMode','fixedRate', ...
                'Period',0.05, ...
                'TimerFcn', @(~,~)readTimerFcn(app));
        end

        function update(app)
        end
    end

    % ========= CALLBACKS =========
    methods (Access = private)

        function startMeasurement(app)
            if strcmp(app.myTimer.Running,'off')
                app.time = [];
                app.values = [];
                app.t0 = tic;
                start(app.myTimer);
            end
        end

        function stopMeasurement(app)
            if strcmp(app.myTimer.Running,'on')
                stop(app.myTimer);
            end
        end

        function toggleMode(app)

            if strcmp(app.myTimer.Running,'on')
                stop(app.myTimer);
            end

            if app.sensorMode == "ambient"
                app.sensorMode = "reflect";
                app.sensor.Mode = 'ReflectedLight';
            else
                app.sensorMode = "ambient";
                app.sensor.Mode = 'AmbientLight';
            end

            app.ModeLabel.Text = "Mode: " + app.sensorMode;
        end

        function readTimerFcn(app)

            val = readLightIntensity(app.sensor);
            t = toc(app.t0);

            app.time(end+1) = t;
            app.values(end+1) = val;

            plot(app.Ax, app.time, app.values);
        end
    end
end
