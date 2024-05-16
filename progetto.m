%% Embedded parameters for DC motor
km = 6.88
Tm = 0.065
A = [0 1; 0 -1/Tm]
B = [0 ;km/Tm]
C = [1 0]
D = 0

%% Espansione dello stato
A_s = [0 1 0; 0 -1/Tm 0; 1 0 0]
B_s = [0;km/Tm;0]
C_s = [1 0 0]
D_s = 0

Q = [100 0 0; 0 0.01 0; 0 0 0.01]
R = 0.001
[K,S,P]=lqr(A_s,B_s,Q,R)
[K2,S,P]=lqi(ss(A,B,C,D),Q,R)
r=50
%%
kr = -1/(C*inv(A-B*K)*B);% guaranteeing reference regulation
