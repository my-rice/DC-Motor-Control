clear all, clc;
%% Embedded parameters for DC motor
%km = 6.88; rpm -> 0.7205. %k = 0.85; motore 25D
%Tm = 0.065;
Ts = 0.005;
Tfs = 0.00025;
alpha = exp(-Tfs/Ts)

km = 0.6876;
kt = 1/km
k = kt;
%Tm = 0.065;
L = 0.01; %0.0082;
R = 2.0;


Im = 0.059;
b = 0.016

s = tf('s');
G = 1/(L*s+R);

C = 1.6667*(s+30)/s;

Ts = 0.005;
Cd = c2d(C,Ts,'Tustin')
