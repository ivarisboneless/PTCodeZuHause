function out = lightReadWithLoop(brickObj, numberOfSeconds)
% out = lightReadWithLoop(brickObj, 5)

    values = [];
    times  = [];

    % Start stopwatch
    t0 = tic;

    % Keep reading until time is up
    while toc(t0) < numberOfSeconds
        values(end+1) = brickObj.sensor1.value; %#ok<AGROW>
        times(end+1)  = toc(t0);                %#ok<AGROW>
    end

    % --- Plot 1: value over time ---
    figure;
    plot(times, values, 'LineWidth', 1.5);
    grid on;
    xlabel('Zeit ab Start [s]');
    ylabel('Lichtsensor-Wert');
    title('Lichtsensor: Messwerte über der Zeit');

    % --- Plot 2: delta time between measurements ---
    if numel(times) >= 2
        dt = diff(times);
        tMid = times(2:end);        % time points for dt (aligned to second sample)
        dtMean = mean(dt);

        figure;
        plot(tMid, dt, 'LineWidth', 1.5);
        grid on;
        hold on;
        yline(dtMean, '--', 'Mittelwert \Deltat', 'LineWidth', 1.5);
        xlabel('Zeit ab Start [s]');
        ylabel('\Deltat zwischen Messungen [s]');
        title('Zeitdifferenzen zwischen Messungen');
    end

    % Return results in a struct (nice and clean)
    out.values = values;
    out.times  = times;
end
