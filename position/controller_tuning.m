%% WARNING! Execute this code after model_approximation.m to store the variables in the workspace (A,B,C,D)
%% Recheability test
WR = [B A*B A^2*B] % rechability matrix
if(rank(WR)==3)
    disp("The system is recheable!")
else
   disp("The system is not recheable!")
end
%% Recheability test with the extended state space
A_e = [-8.2891 0 8.8101 0; 1 0 0 0; 0 0 -35.2405 0; 0 5.8438 0 0]
B_e = [-1;0;8;0]

WR_e = [B_e A_e*B_e A_e^2*B_e A_e^3] % rechability matrix
if(rank(WR)==4)
    disp("The system is recheable!")
else
   disp("The system is not recheable!")
end

%% LQI implementation and tuning of the matrices
Q = [0.01 0 0 0; 0 15 0 0; 0 0 0.01 0; 0 0 0 0.2] % definition of the matrix
% that weights the states
R =  0.0002 % definition of the matrix that weights the input
[K_tilde,S,e] = lqi(ss(A,B,C,D),Q,R,0) % the lqi function return the values
% for the gains of the state feedback controllore, the last one is of a
% different sign, because the MATLAB lqi function, compute the error as:
% desired_value - output
kr = -1/(C*inv(A-B*K_tilde(1:3))*B) 
%% Discretizing the integral term
% To discretize the state feedback controller, it is just needed to
% discretize the integral term:
sys_int = tf([K_tilde(4)],[1 0])
sys_int_d = c2d(sys_int,Ts,'tustin')
num = tfdata(sys_int_d)
num_int = -num{1}

%% Anti wind-up
[Q_vec,P_vec] = tfdata(sys_int_d,'v');
Q_vec = -Q_vec
Gamma_vec = [1 0];

z_Q_Gamma = tf(Q_vec,Gamma_vec,Ts);

z_antiwindupFunc = tf(Gamma_vec-P_vec,Gamma_vec,Ts);

