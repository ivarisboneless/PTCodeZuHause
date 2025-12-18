%% --- EV3 BAĞLANTI ---
ev3 = EV3();
ev3.connect('usb');

mX = ev3.motorA;   % X axis
mY = ev3.motorC;   % Y axis
mZ = ev3.motorB;   % Pen (Z axis)

mX.limitValue = 400;
mY.limitValue = 400;
mZ.limitValue = 200;

%% --- PARAMETRELER ---
h = 400;   % harf yüksekliği
w = 200;   % harf genişliği
s = 150;   % harfler arası boşluk

%% ================= RWTH =================

%% --- R ---
penDown()
moveY(h)
moveX(w)
moveY(-h/2)
moveX(-w)
moveX(w)
moveY(-h/2)
penUp()

moveX(s)

%% --- W ---
penDown()
moveY(-h)
moveX(w/2)
moveY(h)
moveX(w/2)
moveY(-h)
penUp()

moveX(s)

%% --- T ---
penDown()
moveX(w)
moveX(-w/2)
moveY(h)
moveY(-h)
penUp()

moveX(w/2 + s)

%% --- H ---
penDown()
moveY(h)
moveY(-h/2)
moveX(w)
moveY(h/2)
moveY(-h)
penUp()

%% --- BAĞLANTIYI KES ---
ev3.disconnect();

%% ================= FONKSİYONLAR =================

function moveX(dist)
    mX = evalin('base','mX');
    mX.resetTachoCount();
    mX.speed = sign(dist)*20;
    mX.start();
    while abs(mX.tachoCount) < abs(dist)
        pause(0.01);
    end
    mX.stop();
    pause(0.2);
end

function moveY(dist)
    mY = evalin('base','mY');
    mY.resetTachoCount();
    mY.speed = sign(dist)*20;
    mY.start();
    while abs(mY.tachoCount) < abs(dist)
        pause(0.01);
    end
    mY.stop();
    pause(0.2);
end

function penUp()
    mZ = evalin('base','mZ');
    mZ.resetTachoCount();
    mZ.speed = 15;
    mZ.start();
    while abs(mZ.tachoCount) < 60   % kaldırma açısı
        pause(0.01);
    end
    mZ.stop();
    pause(0.2);
end

function penDown()
    mZ = evalin('base','mZ');
    mZ.resetTachoCount();
    mZ.speed = -15;
    mZ.start();
    while abs(mZ.tachoCount) < 60   % indirme açısı
        pause(0.01);
    end
    mZ.stop();
    pause(0.2);
end
