%% WARNING! Execute this code after model_approximation.m to store the variables in the workspace (A,B,C,D)
%% Observability test
W0 = [C;C*A;C*A^2]; % observability matrix
if(rank(W0)==3)
    disp("The system is observable!")
else
   disp("The system is not observable!")
end

%% Using the pole dominant approximation to set the desired performance of observer dynamic system
Sett_time = 0.2; % faster then the motor model
zeta = 1; % no oscillations
w0 = 5.8/Sett_time; % took from the step response properties of a second 
% order system
p = -w0*zeta*10; % one of the three poles is placed in high frequency (10 
% times higher than the other two poles)

syms s l1 l2 l3
L = [l1;l2;l3];
obs_CC = A-L*C
pol_coeff=charpoly(obs_CC); 
desired_pol=(s^2 + 2*zeta*w0*s + w0^2)*(s-p);
desired_pol_coeff = fliplr(coeffs(desired_pol, s));
sol = solve(pol_coeff==desired_pol_coeff,[l1, l2, l3],"ReturnConditions",true);
l1 = eval(sol.l1)
l2 = eval(sol.l2)
l3 = eval(sol.l3)
L = [l1;l2;l3]; 
% In this block of code, using the polinomial equivalence with closed loop
% matrix of the observer, the L poles values are computed
%% Discretize the observer 
sys_continuos = ss(A-L*C,[B L],eye(3),[0 0; 0 0; 0 0])
sys_discrete = c2d(sys_continuos,0.005,'tustin')