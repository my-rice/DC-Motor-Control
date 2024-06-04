clear all, clc;
%% Embedded parameters for DC motor

Ts = 0.005; % sampling time

% first order lag filter parameters
Tf = Ts/2;
Tfs = Tf/20; %0.000125;
alpha = exp(-Tfs/Tf)

% motor parameters. km is taken from model_approximation.m
km = 0.6876;
kt = 1/km
k = kt;
L = 0.0023; % taken from the constructor advise
R = 2.0; % estimated

Im = 0.0059; % this is the inertia value of 25d motor taken as example
b = 0.016; % this is the friction value of 25d motor taken as example

%% Controller - No Windup
s = tf('s');
G = 1/(L*s+R);
C = 0.5625*(s+80)/s % result of sisotool session
% discretization of the controller
Cd = c2d(C,Ts,'Tustin')

%% Controller - anti-Windup
% Obtaining the anti-windup controller
[Q_vec,P_vec] = tfdata(Cd,'v');
Gamma_vec = [1 0];
z_Q_Gamma = tf(Q_vec,Gamma_vec,Ts);
z_antiwindupFunc = tf(Gamma_vec-P_vec,Gamma_vec,Ts);