% --- LEGO EV3 SHAPE & PICTURE PLOTTER ---
% Using components from the LEGO MINDSTORMS Education EV3 Core Set (45544)[cite: 8, 10].
clear; clc;
mylego = EV3();
mylego.connect('usb');

% --- MOTOR ASSIGNMENTS ---
motors.paper = mylego.motorA; % Y-Axis (Forward/Backward)
motors.rail  = mylego.motorB; % X-Axis (Left/Right)
motors.pen   = mylego.motorC; % Z-Axis (Up/Down) [cite: 8, 13]

pwr = 20;

% --- DRAWING SELECTION ---
% You can call specific shape functions here.
disp('Starting to draw a house...');
drawHouse(motors, pwr);

disp('Drawing complete!');

% --- SHAPE FUNCTIONS ---

function drawHouse(m, pwr)
    % IMPORTANT: Drawing a House involves a square base and a triangle roof.
    
    % 1. Draw the Square Base
    penControl(m.pen, 'down');
    moveMotor(m.rail, pwr, 150);  % Base bottom
    moveMotor(m.paper, pwr, 150); % Right side
    moveMotor(m.rail, pwr, -150); % Top (ceiling)
    moveMotor(m.paper, pwr, -150);% Left side
    penControl(m.pen, 'up');
    
    % 2. Move to position for the Roof
    moveMotor(m.paper, pwr, 150); % Move to top-left corner
    
    % 3. Draw the Triangle Roof
    penControl(m.pen, 'down');
    % Diagonal move: requires moving X and Y simultaneously
    % Since our moveMotor is sequential, we use a simple peak:
    moveMotorParallel(m.rail, m.paper, pwr, 75, 75);  % Up to the peak
    moveMotorParallel(m.rail, m.paper, pwr, 75, -75); % Down to top-right
    penControl(m.pen, 'up');
end

% --- ADVANCED SIMULTANEOUS MOVEMENT ---
function moveMotorParallel(motorX, motorY, pwr, degX, degY)
    % TECHNICAL NOTE: To draw diagonal lines, both motors must run at the same time.
    motorX.resetTachoCount();
    motorY.resetTachoCount();
    
    motorX.power = pwr * sign(degX);
    motorY.power = pwr * sign(degY);
    
    motorX.start();
    motorY.start();
    
    % Wait until both motors reach their targets
    while abs(motorX.tachoCount) < abs(degX) || abs(motorY.tachoCount) < abs(degY)
        if abs(motorX.tachoCount) >= abs(degX), motorX.stop(); end
        if abs(motorY.tachoCount) >= abs(degY), motorY.stop(); end
    end
    motorX.stop();
    motorY.stop();
    pause(0.2);
end

% --- CORE MOVEMENT HELPERS ---
function moveMotor(motorObj, pwr, deg)
    motorObj.resetTachoCount();
    motorObj.power = pwr * sign(deg);
    motorObj.start();
    while abs(motorObj.tachoCount) < abs(deg), end
    motorObj.stop();
    pause(0.2);
end

function penControl(motorObj, action)
    motorObj.resetTachoCount();
    if strcmpi(action, 'down'), motorObj.power = -15; 
    else, motorObj.power = 15; end
    motorObj.start();
    while abs(motorObj.tachoCount) < 60, end
    motorObj.stop();
    pause(0.4);
end
