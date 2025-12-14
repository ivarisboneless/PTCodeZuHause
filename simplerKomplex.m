function phase_simple_ev3()
clc; close all;

%% 1) Input GUI
prompt = {'z1 (e.g. 4+5i):', 'z2 (e.g. 1-2i):', 'op (mul, div, conj, sqrt):'};
answ = inputdlg(prompt, 'Phase simple', [1 40], {'1+1i','1-1i','mul'});
if isempty(answ); return; end

z1 = str2num(answ{1}); %#ok<ST2NM>
z2 = str2num(answ{2}); %#ok<ST2NM>
op = lower(strtrim(answ{3}));

%% 2) Compute result
switch op
    case 'mul'
        res = z1*z2;
    case 'div'
        res = z1/z2;
    case 'conj'
        res = conj(z1);
        z2  = 0;
    case 'sqrt'
        res = sqrt(z1);
        z2  = 0;
    otherwise
        error('Use op = mul, div, conj, sqrt');
end

%% 3) Compass plot
figure;
compass([z1 z2 res]);
grid on; axis equal;
legend('z1','z2','result');
title(['Operation: ' op]);

%% 4) Angles in degrees (0..360)
a1 = mod(rad2deg(angle(z1)), 360); if a1 < 0, a1 = a1 + 360; end
a2 = mod(rad2deg(angle(z2)), 360); if a2 < 0, a2 = a2 + 360; end
ar = mod(rad2deg(angle(res)), 360); if ar < 0, ar = ar + 360; end

fprintf('a1=%.1f°, a2=%.1f°, ar=%.1f°\n', a1, a2, ar);

%% 5) EV3 connect + motors
ev3 = EV3();
ev3.connect('usb');

m1 = ev3.motorA;
m2 = ev3.motorB;

gear  = 45;   % change if your pointer gear ratio differs
power = 40;

%% 6) Move motor A to z1 phase
m1.resetTachoCount();
m1.limitMode  = 'Tacho';
m1.brakeMode  = 'Brake';
m1.power      = power;
m1.limitValue = gear*a1;
m1.start(); m1.waitFor(); m1.stop();

%% 7) Move motor B to z2 phase
m2.resetTachoCount();
m2.limitMode  = 'Tacho';
m2.brakeMode  = 'Brake';
m2.power      = power;
m2.limitValue = gear*a2;
m2.start(); m2.waitFor(); m2.stop();

pause(1);

%% 8) Move motor A to result phase
m1.resetTachoCount();
m1.limitMode  = 'Tacho';
m1.brakeMode  = 'Brake';
m1.power      = power;
m1.limitValue = gear*ar;
m1.start(); m1.waitFor(); m1.stop();

pause(1);

%% 9) Return both to 0° (up)
m1.resetTachoCount();
m1.limitMode  = 'Tacho';
m1.brakeMode  = 'Brake';
m1.power      = power;
m1.limitValue = 0;
m1.start(); m1.waitFor(); m1.stop();

m2.resetTachoCount();
m2.limitMode  = 'Tacho';
m2.brakeMode  = 'Brake';
m2.power      = power;
m2.limitValue = 0;
m2.start(); m2.waitFor(); m2.stop();

ev3.disconnect();
end
