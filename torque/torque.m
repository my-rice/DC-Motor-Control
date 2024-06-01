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
L = 0.0472; %0.0082;
R = 2.0;

Im = 0.0059;
b = 0.016;

%% Controller - No Windup
s = tf('s');
G = 1/(L*s+R);
C = 1.6667*(s+30)/s; % sisotool

Ts = 0.005;
Cd = c2d(C,Ts,'Tustin')

%% Controller - Windup

[Q_vec,P_vec] = tfdata(Cd,'v');
Gamma_vec = [1 0];
z_Q_Gamma = tf(Q_vec,Gamma_vec,Ts);
z_antiwindupFunc = tf(Gamma_vec-P_vec,Gamma_vec,Ts);


%Kp = 1.6667
%Ki = 30*1.6667;
%Ti = 1/Ki;
%antiwindup = 1/(1+Ti*s);
%antiwindup_d = c2d(antiwindup,Ts,'Tustin');
%[num,den] = tfdata(antiwindup_d);
%num = cell2mat(num)
%den = cell2mat(den)