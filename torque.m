clear all, clc;
%% Embedded parameters for DC motor
%km = 6.88;
%Tm = 0.065;

k = 0.85;
L = 0.0082;
R = 3.2;
Im = 0.059;
b = 0.016

% velocità espressa in rpm


Ki = 5049.4;
Kp = 5049.4*0.01;

s = tf('s');
G = 1/(L*s+R);
    