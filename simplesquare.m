function simplesquare()

clc; clear;

%% Connect
ev3 = EV3();
ev3.connect;

%% Motors
mX = ev3.motorA;   % X axis
mY = ev3.motorB;   % Y axis

%% Parameters
P = 25;        % motor power
kX = -9;       % deg per unit (X)
kY =  8;       % deg per unit (Y)
L  = 10;       % square side length (units)

%% Reset
mX.resetTachoCount();
mY.resetTachoCount();

%% Draw square
moveX(L);
moveY(L);
moveX(-L);
moveY(-L);

disp("Square done.");

%% ---------- MOVE FUNCTIONS ----------

    function moveX(units)
        target = mX.tachoCount + units*kX;
        mX.power = P*sign(units);
        mX.start();
        while abs(target - mX.tachoCount) > 10
            pause(0.01);
        end
        mX.stop();
    end

    function moveY(units)
        target = mY.tachoCount + units*kY;
        mY.power = P*sign(units);
        mY.start();
        while abs(target - mY.tachoCount) > 10
            pause(0.01);
        end
        mY.stop();
    end

end
