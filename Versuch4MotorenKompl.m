function phase_visual_ev3()
% PHASE_VISUAL_EV3
% Input: z1, z2, operation = mul/div/conj/sqrt
% Output: compass plot + (optional) EV3 motors show phases

clc; close all;

%% --------- 1) Input GUI ----------
prompt  = {'Enter first complex number z1 (e.g. 4+5i):', ...
           'Enter second complex number z2 (e.g. 1-2i):', ...
           'Operation (mul, div, conj, sqrt):'};
dlgtitle = 'Phase visualizer';
dims     = [1 50];

answ = inputdlg(prompt, dlgtitle, dims, {'1+1i','1-1i','mul'});
if isempty(answ); disp('Cancelled.'); return; end

z1 = str2num(answ{1}); %#ok<ST2NM>
z2 = str2num(answ{2}); %#ok<ST2NM>
op = lower(strtrim(answ{3}));

if isempty(z1) || isempty(z2)
    error('z1 or z2 could not be parsed. Use format like 3+4i (with i).');
end

%% --------- 2) Compute result ----------
switch op
    case 'mul'
        res = z1 * z2;

    case 'div'
        res = z1 / z2;

    case 'conj'
        res = conj(z1);
        z2  = 0;   % not used

    case 'sqrt'
        res = sqrt(z1);
        z2  = 0;   % not used

    otherwise
        error('Unknown operation. Use: mul, div, conj, sqrt');
end

%% --------- 3) Compass plot ----------
figure('Name','Compass phases');
compass([z1, z2, res]);
grid on;
axis equal;
legend('z1','z2','result','Location','best');
title(['Operation: ', op]);

%% --------- 4) Convert phases (correctly!) ----------
% angle() is radians -> rad2deg converts to degrees.
a1 = wrapTo360(rad2deg(angle(z1)));
a2 = wrapTo360(rad2deg(angle(z2)));
ar = wrapTo360(rad2deg(angle(res)));

fprintf('z1 phase = %.1f° | z2 phase = %.1f° | result phase = %.1f°\n', a1, a2, ar);

%% --------- 5) Optional: EV3 motor display ----------
% If EV3 is disconnected, script STILL completes.
try
    ev3 = EV3();
    ev3.connect('usb');  % or ev3.connect('usb','beep','on');

    m1 = ev3.motorA;   % pointer 1
    m2 = ev3.motorB;   % pointer 2

    gear = 45;         % your setup (change if needed)
    dir1 = 1;          % flip to -1 if motor direction is reversed
    dir2 = 1;          % flip to -1 if motor direction is reversed

    power = 40;
    brake = 'Brake';

    % Show z1 and z2 first
    pointMotor(m1, dir1*gear*a1, power, brake);
    pointMotor(m2, dir2*gear*a2, power, brake);

    pause(1);

    % Then show result on motor 1
    pointMotor(m1, dir1*gear*ar, power, brake);

    pause(1);

    % Return both to "up" (0°)
    pointMotor(m1, 0, power, brake);
    pointMotor(m2, 0, power, brake);

    ev3.disconnect();

catch ME
    warning('EV3 part skipped: %s', ME.message);
    warning('Tip: replug USB, close old EV3 objects (clear classes), then run again.');
end

end

%% ---------------- Helper ----------------
function pointMotor(m, targetDeg, power, brakeMode)
% Moves motor by targetDeg relative degrees (safe + simple)

% reset means "0" becomes our reference
m.resetTachoCount();

m.limitMode  = 'Tacho';
m.brakeMode  = brakeMode;

% direction via sign of power
if targetDeg < 0
    m.power     = -abs(power);
    m.limitValue = abs(targetDeg);
else
    m.power     = abs(power);
    m.limitValue = abs(targetDeg);
end

m.start();
m.waitFor();
m.stop();
end

function a = wrapTo360(a)
a = mod(a, 360);
if a < 0, a = a + 360; end
end
