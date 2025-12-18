ev3 = EV3();
ev3.connect('usb');

mX = ev3.motorA;   % X axis
mY = ev3.motorC;   % Y axis

mX.limitValue = 400;
mY.limitValue = 400;

h = 400;   % yükseklik
w = 200;   % genişlik
s = 150;   % boşluk

%% --- R ---
moveY(h)
moveX(w)
moveY(-h/2)
moveX(-w)
moveX(w)
moveY(-h/2)

moveX(s)

%% --- W ---
moveY(-h)
moveX(w/2)
moveY(h)
moveX(w/2)
moveY(-h)

moveX(s)

%% --- T ---
moveX(w)
moveX(-w/2)
moveY(h)
moveY(-h)

moveX(w/2 + s)

%% --- H ---
moveY(h)
moveY(-h/2)
moveX(w)
moveY(h/2)
moveY(-h)

ev3.disconnect();

%% --------- FONKSİYONLAR ---------

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
