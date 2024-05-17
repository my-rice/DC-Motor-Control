clear all, clc;
%% Embedded parameters for DC motor
km = 6.88;
Tm = 0.065;
A = [0 1; 0 -1/Tm];
B = [0 ;km/Tm];
C = [1 0];
D = 0;

r = 10;
disturbance = 10;

%% Sistema non esteso
sys = ss(A,B,C,D);
WR = [B A*B]
rank(WR) %il sistema è raggiungibile.


Q = [100 0; 0 0.01];
R = 0.001
K = lqr(ss(A,B,C,D),Q,R)
kr = -1/(C*inv(A-B*K)*B)

step(ss(A-B*K,B.*kr,C,D))


%% Espansione dello stato
A_s = [0 1 0; 0 -1/Tm 0; 1 0 0]
B_s = [0;km/Tm;0]
C_s = [1 0 0]
D_s = 0

% Raggiungibilità del sistema aumentato
Wr = [B A*B A*A*B; 0 C*B C*A*B];
rank(Wr)

Q = [100 0 0; 0 0.01 0; 0 0 0.01]
R = 0.001
[K_tilde,S,P]=lqr(A_s,B_s,Q,R)
K = [K_tilde(1) K_tilde(2)]
kr = -1/(C*inv(A-B.*K)*B) 

simout = sim("LQR.slx");
t = simout.t;
y = simout.y;
u = simout.u;
y_stepinfo = stepinfo(y,t,r) 
u_stepinfo = stepinfo(u,t,u(end))
min(u)
max(u)