%% === D) BRAKING DISTANCE VS POWER (COAST) ===
powers = [20 30 40 50 60 70 80];
nRep   = 3;

% Measure/enter your wheel diameter (cm)
wheelDiameter_cm = 5.6;                       % <-- CHANGE THIS
wheelCirc_cm = pi * wheelDiameter_cm;

% Helper: convert tacho degrees to distance (cm)
deg2cm = @(deg) (deg/360) * wheelCirc_cm;

results = struct();
results.power = powers;
results.brake_cm = zeros(size(powers));
results.brake_cm_all = zeros(numel(powers), nRep);

% Coast = measure real braking roll-out
motorR.brakeMode = 'Coast';
motorL.brakeMode = 'Coast';

motorR.speedRegulation = 'Off';
motorL.speedRegulation = 'Off';

startRunTime = 1.2;   % seconds to let speed stabilize (tweak)
pauseAfterStop = 1.5; % seconds to let it fully stop (tweak)

for i = 1:numel(powers)
    P = powers(i);
    fprintf("\nPower %d\n", P);

    for r = 1:nRep
        % Reset tacho
        resetRotation(motorR);
        resetRotation(motorL);

        % Start driving straight
        motorR.power = P;
        motorL.power = P;
        motorR.syncedStart(motorL,'turnRatio',0);

        pause(startRunTime);

        % Stop motors (coast)
        motorR.syncedStop();

        % Wait until robot stops rolling
        pause(pauseAfterStop);

        % Read rollout distance from tacho
        degR = readRotation(motorR);
        degL = readRotation(motorL);
        cmR  = deg2cm(degR);
        cmL  = deg2cm(degL);

        brake_cm = (cmR + cmL)/2; % average both wheels
        results.brake_cm_all(i,r) = brake_cm;

        fprintf("  rep %d: %.2f cm\n", r, brake_cm);

        pause(0.8); % time to reposition robot
    end

    results.brake_cm(i) = mean(results.brake_cm_all(i,:));
    fprintf("mean: %.2f cm\n", results.brake_cm(i));
end

% Plot
figure; grid on; hold on;
plot(results.power, results.brake_cm, 'o-','LineWidth',1.5);
xlabel('Power'); ylabel('Braking distance (cm)');
title('Braking distance vs Power (COAST)');
