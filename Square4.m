clc; clear;

% ===== CONNECT =====
ev3 = EV3();
ev3.connect('usb');   % or ev3.connect

mx = ev3.motorA;      % X motor
my = ev3.motorB;      % Y motor

P = 20;               % LOW power (safe)

% ===== DRAW TINY SQUARE =====
mx.power =  P;   mx.start(); pause(0.6); mx.stop();   % right
my.power =  P;   my.start(); pause(0.6); my.stop();   % up
mx.power = -P;   mx.start(); pause(0.6); mx.stop();   % left
my.power = -P;   my.start(); pause(0.6); my.stop();   % down

% ===== EMERGENCY STOP =====
mx.stop();
my.stop();
ev3.disconnect();

disp("DONE – square finished");
