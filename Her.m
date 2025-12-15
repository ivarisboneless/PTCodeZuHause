methods (Access = private)

    function applySensorMode(app)
        % app.config.sensorMode: 'ambient' or 'reflect'
        if strcmp(app.config.sensorMode,'ambient')
            app.sensor.Mode = 'AmbientLight';
        else
            app.sensor.Mode = 'ReflectedLight';
        end
    end

    function readLightTimerFcn(app)
        % Timer tick: read sensor, update buffers, plot

        ud = app.myTimer.UserData;

        val = readLightIntensity(app.sensor);
        t   = toc(ud.t0);

        % shift left (ring buffer)
        ud.timeData(1:end-1)        = ud.timeData(2:end);
        ud.measurementData(1:end-1) = ud.measurementData(2:end);

        ud.timeData(end)        = t;
        ud.measurementData(end) = val;

        % plot in GUI
        plot(app.UIAxes, ud.timeData, ud.measurementData);
        grid(app.UIAxes,'on');
        xlabel(app.UIAxes,'Time [s]');
        ylabel(app.UIAxes,'Light');

        app.myTimer.UserData = ud;
    end

end
