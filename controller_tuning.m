%% WARNING! Execute this code after model_approximation.m to store the variables in the workspace (A,B,C,D)
%% Recheability test
WR = [B A*B A^2*B] % rechability matrix
if(rank(WR)==3)
    disp("The system is recheable!")
else
   disp("The system is not recheable!")
end
%% LQI implementation and tuning of the matrices
Q = [0.01 0 0 0; 0 15 0 0; 0 0 0.01 0; 0 0 0 1] % definition of the matrix
% that weights the states
R =  0.08 % definition of the matrix that weights the input
[K_tilde,S,e] = lqi(ss(A,B,C,D),Q,R,0) % the lqi function return the values
% for the gains of the state feedback controllore, the last one is of a
% different sign, because the MATLAB lqi function, compute the error as:
% desired_value - output
kr = -1/(C*inv(A-B*K_tilde(1:3))*B) % DALLA TEORIA, we calculate kr
%% Discretizing the integral term
% To discretize the state feedback controller, it is just needed to
% discretize the integral term:
K_discreta = K_tilde(1:3)
sys_int = tf([K_tilde(4)],[1 0])
sys_int_d = c2d(sys_int,Ts,'tustin')
num = tfdata(sys_int_d)
num_int = -num{1}