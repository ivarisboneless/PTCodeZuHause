function out = lightReadWithTimer(brickObj, numberOfSeconds, connectionType)
% out = lightReadWithTimer(brickObj, 5, 'usb')
% Timer period: 0.05 for USB, 0.10 for Bluetooth (per Versuch)

    %might not be needed 
    if strcmp(connectionType,'usb')
        period = 0.05;
    elseif strcmp(connectionType,'bluetooth')
        period = 0.10;
    else
        error("connectionType must be 'usb' or 'bluetooth'.");
    end

    %  UserData struct (this is the "memory" of the timer) so that the timer doesnot crash out lol 
    myUserData.brickObj = brickObj;
    myUserData.values   = [];
    myUserData.times    = [];
    myUserData.t0       = tic;             % start stopwatch here
    myUserData.tEnd     = numberOfSeconds; % stop after this time

    %  create timer 
    t = timer;
    t.ExecutionMode = 'fixedRate';      % try also: fixedDelay / fixedSpacing
    t.Period        = period;
    t.TimerFcn      = @readLightTimerFcn;
    t.UserData      = myUserData;

    % --- start timer (non-blocking) ---
    start(t);

    % Wait until timer stops itself, then clean up
    wait(t);
    data = t.UserData;
    stop(t);
    delete(t);

    %  Plot results (same idea as loop version) 
    figure;
    plot(data.times, data.values, 'LineWidth', 1.5);
    grid on;
    xlabel('Zeit ab Start [s]');
    ylabel('Lichtsensor-Wert');
    title('Timer-Messung: Werte über Zeit');

    if numel(data.times) >= 2
        dt = diff(data.times);
        tMid = data.times(2:end);
        dtMean = mean(dt);

        figure;
        plot(tMid, dt, 'LineWidth', 1.5);
        grid on;
        hold on;
        yline(dtMean, '--', 'Mittelwert \Deltat', 'LineWidth', 1.5);
        xlabel('Zeit ab Start [s]');
        ylabel('\Deltat zwischen Messungen [s]');
        title('Timer-Messung: Zeitdifferenzen');
    end

    out.values = data.values;
    out.times  = data.times;
end
