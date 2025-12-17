% --- LEGO EV3 WORD PLOTTER INITIALIZATION ---
% Designed for the LEGO MINDSTORMS Education EV3 Core Set[cite: 8, 9].
clear; clc;
mylego = EV3();
mylego.connect('usb');

% --- MOTOR PORT MAPPING ---
% According to standard builds for this Core Set:
% Port A: Moves the paper (Y-Axis)
% Port B: Moves the pen rail left/right (X-Axis)
% Port C: Raises/Lowers the pen (Z-Axis)
motors.paper = mylego.motorA; 
motors.rail  = mylego.motorB; 
motors.pen   = mylego.motorC; 

% --- SETTINGS ---
pwr = 20;             % Default motor power for drawing
charSpacing = 80;     % Horizontal spacing between letters (in degrees)

% --- WORD SELECTION ---
% Input the word you want the EV3 to plot.
targetWord = 'HHA'; 
targetWord = upper(targetWord); % Convert to uppercase to match library functions

disp(['Currently plotting: ', targetWord, '...']);

% --- MAIN CHARACTER LOOP ---
% This loop iterates through each character of your string[cite: 58, 61].
for i = 1:length(targetWord)
    currentLetter = targetWord(i);
    
    % --- CHARACTER LIBRARY ---
    % Calls the specific function based on the current character.
    switch currentLetter
        case 'H'
            drawH(motors, pwr);
        case 'A'
            drawA(motors, pwr);
        % Additional letters (B, C, D...) can be added as functions below.
        otherwise
            disp(['Warning: Letter "', currentLetter, '" is not in the library.']);
    end
    
    % --- CHARACTER SPACING ---
    % After drawing a letter, move the rail forward to create a gap[cite: 131, 218].
    moveMotor(motors.rail, 30, charSpacing);
end

disp('Plotting process complete.');

% --- CHARACTER DRAWING FUNCTIONS ---

function drawH(m, pwr)
    % IMPORTANT: Logic for the letter 'H'
    % 1. Left Vertical Pillar
    penControl(m.pen, 'down');
    moveMotor(m.paper, pwr, 200); % Draw left side
    penControl(m.pen, 'up');
    
    % 2. Move to Center for the Bridge
    moveMotor(m.paper, pwr, -100); % Move back to center height
    penControl(m.pen, 'down');
    moveMotor(m.rail, pwr, 60);    % Draw horizontal bridge
    penControl(m.pen, 'up');
    
    % 3. Right Vertical Pillar
    moveMotor(m.paper, pwr, -100); % Move to the top of the right pillar
    penControl(m.pen, 'down');
    moveMotor(m.paper, pwr, 200);  % Draw right side
    penControl(m.pen, 'up');
end

function drawA(m, pwr)
    % IMPORTANT: Simple logic for the letter 'A'
    % 1. Draw the Outline
    penControl(m.pen, 'down');
    moveMotor(m.paper, pwr, 200); % Draw left slope/vertical
    moveMotor(m.rail, pwr, 60);   % Draw top horizontal
    moveMotor(m.paper, pwr, -200);% Draw right slope/vertical
    penControl(m.pen, 'up');
    
    % 2. Draw the Crossbar
    moveMotor(m.paper, pwr, 100); % Move back to the middle
    penControl(m.pen, 'down');
    moveMotor(m.rail, pwr, -60);  % Draw the crossbar bridge
    penControl(m.pen, 'up');
    
    % Reset rail position to the right of the letter
    moveMotor(m.rail, pwr, 60);   
end

% --- CORE MOVEMENT HELPERS ---

function moveMotor(motorObj, pwr, deg)
    % TECHNICAL NOTE: Resetting Tacho Count ensures precision.
    % This allows us to move exactly X degrees from the current position[cite: 62, 219].
    motorObj.resetTachoCount();
    motorObj.power = pwr * sign(deg);
    motorObj.start();
    
    % Wait for the motor to reach the specified degree rotation.
    while abs(motorObj.tachoCount) < abs(deg)
    end
    
    motorObj.stop();
    pause(0.2); % Stabilize hardware before the next command
end

function penControl(motorObj, action)
    % TECHNICAL NOTE: Z-Axis Height Control
    % 'down' lowers the pen to touch the paper; 'up' lifts it[cite: 89, 90, 194].
    motorObj.resetTachoCount();
    
    if strcmpi(action, 'down')
        motorObj.power = -15; % Negative power typically lowers the pen
    else
        motorObj.power = 15;  % Positive power lifts the pen
    end
    
    motorObj.start();
    
    % We use a set 60-degree rotation to manage pen height[cite: 73, 82].
    while abs(motorObj.tachoCount) < 60
    end
    
    motorObj.stop();
    pause(0.4); % Delay to ensure the pen is fully raised/lowered
end
