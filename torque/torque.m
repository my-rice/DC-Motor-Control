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
L = 0.0023; %0.0082;
R = 2.0;

Im = 0.0059;
b = 0.016;

%% Controller - No Windup
s = tf('s');
G = 1/(L*s+R);
C = 0.5625*(s+80)/s
Cd = c2d(C,Ts,'Tustin')

%% Controller - Windup

[Q_vec,P_vec] = tfdata(Cd,'v');
Gamma_vec = [1 0];
z_Q_Gamma = tf(Q_vec,Gamma_vec,Ts);
z_antiwindupFunc = tf(Gamma_vec-P_vec,Gamma_vec,Ts);

%% Plot 

y = out.y;
u = out.u;
t = out.t;
ref = out.r;
ref = ref(:,:).';
r = [];
% create a reference signal with the same length as the output. r contains the reference signal and every 5 seconds the reference changes
for i = 1:length(t)
    if t(i) < 3
        r(i) = ref(1);
    elseif t(i) < 6
        r(i) = ref(2);
    else
        r(i) = ref(3);
    end
end


figure(1)
plot(t,y)
hold on
plot(t,r)
hold off
title('Torque')
xlabel('Time (s)')
ylabel('Torque (N*m)')
legend('Torque', 'Reference')

figure(2)
plot(t,u)
title('Voltage')
xlabel('Time (s)')
ylabel('Voltage (V)')
legend('Voltage')
