% --- LEGO EV3 PLOTTER INITIALIZATION ---
clear; clc;
disp('Establishing Connection to EV3...');

% Initialize connection to the EV3 brick via USB
mylego = EV3();
mylego.connect('usb');

% IMPORTANT: Define Motor Ports
% Port A controls paper movement (Y-Axis) [cite: 4, 8]
% Port B controls the rail/marker slide (X-Axis) [cite: 6, 8]
% Port C controls the pen lifting mechanism (Z-Axis) [cite: 8, 13]
paperMotor = mylego.motorA;   
railMotor  = mylego.motorB;   
penMotor   = mylego.motorC;   

% Set Brake Mode
% Setting 'Brake' ensures the motor stops precisely at the target degree 
% instead of coasting to a halt, which is critical for accurate drawing.
paperMotor.brakeMode = 'Brake'; 
railMotor.brakeMode  = 'Brake'; 
penMotor.brakeMode   = 'Brake'; 

disp('System Ready!');

% --- PHASE 1: PAPER FEEDING ---
disp('Feeding paper into the system...');
% Initial rotation of 800 degrees to position the paper under the pen
moveMotor(paperMotor, 20, 800); 
pause(1);

% --- PHASE 2: DRAWING THE LETTER 'H' ---
disp('Drawing operation started...');

% 1. Draw the left vertical line
penControl(penMotor, 'down');
moveMotor(paperMotor, 20, 200);
penControl(penMotor, 'up');

% 2. Move to position for the center horizontal line
moveMotor(paperMotor, 20, -100); % Return halfway up
penControl(penMotor, 'down');
moveMotor(railMotor, 30, 100);   % Draw horizontally to the right
penControl(penMotor, 'up');

% 3. Draw the right vertical line
moveMotor(paperMotor, 20, -100); % Return to the top (Rail is already on the right)
penControl(penMotor, 'down');
moveMotor(paperMotor, 20, 200);  % Draw vertically down
penControl(penMotor, 'up');

disp('Drawing operation completed.');

% --- PHASE 3: PAPER EJECTION ---
disp('Ejecting paper...');
% Push the paper out completely
moveMotor(paperMotor, 30, 500);
disp('Process finished.');

% --- HELPER FUNCTIONS ---

function moveMotor(motorObj, pwr, deg)
    % IMPORTANT: Precision Control
    % We reset the Tacho Count before every movement so the motor starts 
    % counting from zero for the current operation.
    motorObj.resetTachoCount();
    motorObj.power = pwr;
    motorObj.start();
    
    % Monitoring Loop: The program pauses here until the absolute value of 
    % the motor's rotation reaches the target degrees.
    while abs(motorObj.tachoCount) < abs(deg)
        % Wait until target position is reached
    end
    
    motorObj.stop();
    pause(0.2); % Small delay to allow the mechanism to settle
end

function penControl(motorObj, action)
    % IMPORTANT: Pen Height Management
    % This handles the lifting (Up) and lowering (Down) of the marker.
    motorObj.resetTachoCount();
    
    if strcmpi(action, 'down')
        motorObj.power = -15; % Negative power lowers the pen
    else
        motorObj.power = 15;  % Positive power lifts the pen
    end
    
    motorObj.start();
    % We move exactly 60 degrees to prevent the motor from stalling 
    % or damaging the pen mechanism.
    while abs(motorObj.tachoCount) < 60 
    end
    
    motorObj.stop();
    pause(0.5); % Ensure the pen is fully moved before starting the next coordinate
end
