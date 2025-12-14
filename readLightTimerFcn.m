function readLightTimerFcn(timerObj, event)
% Called automatically by MATLAB timer

    data = timerObj.UserData;

    % Read sensor
    v = data.brickObj.sensor1.value;
    t = toc(data.t0);

    % Save
    data.values(end+1) = v;
    data.times(end+1)  = t;

    % Stop condition (after numberOfSeconds)
    if t >= data.tEnd
        timerObj.UserData = data;  % save before stopping
        stop(timerObj);
        return;
    end

    % Save back to timer
    timerObj.UserData = data;
end

% this is how it is runned brick = lightConnectEV3('bluetooth','reflect'); out   = lightReadWithTimer(brick, 5, 'bluetooth'); lightDisconnectEV3(brick);
