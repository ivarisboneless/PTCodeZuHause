function phase_simple_ev3_simple()
clc; close all;

%% 1) Input
prompt = {'z1 (e.g. 4+5i):', 'z2 (e.g. 1-2i):', 'op (mul, div, conj, sqrt):'};
answ = inputdlg(prompt, 'Phase simple', [1 40], {'1+1i','1-1i','mul'});
if isempty(answ); return; end

z1 = str2num(answ{1}); %#ok<ST2NM>
z2 = str2num(answ{2}); %#ok<ST2NM>
op = lower(strtrim(answ{3}));

%% 2) Result
switch op
    case 'mul',  res = z1*z2;
    case 'div',  res = z1/z2;
    case 'conj', res = conj(z1); z2 = 0;
    case 'sqrt', res = sqrt(z1); z2 = 0;
    otherwise, error('op must be mul, div, conj, sqrt');
end

%% 3) Plot
figure; compass([z1 z2 res]); grid on; axis equal;
legend('z1','z2','result'); title(['Operation: ' op]);

%% 4) Angles (0..360)
a1 = wrap360(rad2deg(angle(z1)));
a2 = wrap360(rad2deg(angle(z2)));
ar = wrap360(rad2deg(angle(res)));
fprintf('a1=%.1f°, a2=%.1f°, ar=%.1f°\n', a1, a2, ar);

%% 5) EV3 connect
ev3 = EV3();
ev3.connect('usb');

m1 = ev3.motorA;
m2 = ev3.motorB;

gear  = 45;   % motor degrees per pointer degree (change for your build)
power = 35;   % 20..50 is usually safe
timeoutS = 12;

%% 6) Move A -> a1, B -> a2, A -> ar   (NO waitFor!)
moveMotorAbs(m1, gear*a1, power, timeoutS);
moveMotorAbs(m2, gear*a2, power, timeoutS);
pause(0.5);
moveMotorAbs(m1, gear*ar, power, timeoutS);

%% 7) Stop + disconnect
m1.stop(); m2.stop();
pause(0.3);
ev3.disconnect();
end

% -------- helper functions --------
function ang = wrap360(ang)
ang = mod(ang, 360);
if ang < 0, ang = ang + 360; end
end

function moveMotorAbs(m, targetDeg, power, timeoutS)
% Simple: reset tacho to 0, then move forward to targetDeg and stop.
% (Assumes targetDeg >= 0)

targetDeg = abs(targetDeg);

m.stop();
pause(0.05);

m.resetTachoCount();
m.limitMode  = 'Tacho';
m.brakeMode  = 'Brake';
m.power      = abs(power);
m.limitValue = targetDeg;

m.start();

t0 = tic;
while abs(m.tachoCount) < targetDeg
    pause(0.05);
    if toc(t0) > timeoutS
        break; % safety
    end
end

m.stop();
pause(0.2);
end
