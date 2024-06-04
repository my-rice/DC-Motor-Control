clear all
close all
clc

%% Definition of sampling time and input/output signal retrieved from the motor
Ts = 0.005;
y = load('motor_data/y_motore.mat').y;
t = load('motor_data/t_motore.mat').t;
u(1) = 12;

%% Filter signal 
% With 10 seconds, and Ts = 0.005 we have 2000 samples, so 29 windowSize
% means is equal to 1.45%
windowSize = 29
b=(1/windowSize)*ones(1,windowSize)
a = 1
y_filtered = filter(b,a,y)


% Plot the results for visualization
figure;
plot(y);
hold on;
plot(y_filtered);
legend('Original y', 'Filtered Signal');
xlabel('Sample Index');
ylabel('Amplitude');
title('Moving Average Filter');
grid on;

%% Areas approach to obtain the motor model

n = size(y_filtered)
S1 = 0
y_overline = y_filtered(length(y_filtered))
%for i = 1:n-1
%    S1 = S1 +(y_overline-y_filtered(i))*(t(i+1)-t(i));% definizione di integrale, f * \delta T, che suppongo essere sufficientemente piccolo
%end 
% Instead of computing the area through the for loop above, it is used a
% more precise function provided by MATLAB: trapz, that calculate the area
% using the trapezoid method
Q = trapz(t(1:length(t)),y_filtered(1:length(y_filtered)))
ext_area = y_overline*t(round(length(t)))-Q
S1 = ext_area/y_overline
mu = y_overline / u(1)

f=find(t<S1) % In this way it is found the index of t such that t is equal 
% to T+tau
S2 = trapz(t(1:length(f)),y_filtered(1:length(f))) % it is computed the area
% as suggested by the areas approach, until T+tau
T = S2*exp(1)/y_overline % it is calculated T from the formula (1):
%(1) S2 = y_overline*T/e 
tau = S1-T % tau is calculated from the formula (2):
%(2) S1 = y_overline(T+tau) 
% note that, in this case, the variable S1 is already divided by y_overline
s=tf('s')
G = mu/(1+s*T)*exp(-tau*s)
% This is the tf function representing the motor model, with the delay
% introducted by the approximation of the model
G_senza_pade = mu/(1+s*T)
% This is the same tf, without the delay

%% From Volt-Speed tf to Volt-Position (rad) state space
G_senza_delay = G_senza_pade/s/9.5493; % since that the previously tf was mapping the
% u representing the voltage, to the y representing the speed in rpm, it is
% divided by s to map the same u to the y representing the position, and
% it is divided by the constant 9.5493 for represent the position in rad
num = [0 0 6.732];
den = [1.152 9.549 0];
[A,B,C,D] = tf2ss(num,den); 
% Here it is calculated the state space from the tf, without the delay

%% Adding the delay and using padè approximation in state space
sys_with_delay = ss(A,B,C,D,'InputDelay',tau) % it is added the delay calculated before
% in the state space model
sys_pade = pade(sys_with_delay,1,Inf,Inf) % using the padè function provided by
% MATLAB to get a better approximation of the state space matrices. It is
% equivalent to what it was seen in the course, but in this way the
% matrices are instantly computed.
A = sys_pade.A
B = sys_pade.B
C = sys_pade.C
D = sys_pade.D
