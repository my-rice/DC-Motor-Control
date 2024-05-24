A = [-9.2083 0 8.1034; 1.0000 0 0; 0 0 -32.4138];
B = [-1;0;8];
C = [0, 6.486, 0];
D = 0;

K_tilde = [1.0710, 10.3987, 0.2638, -0.7581];
kr = -1/(C*inv(A-B*K_tilde(1:3))*B);

%
W0 = [C;C*A;C*A^2];
rank(W0)

% calcolo dei coefficienti del polinomio desiderato
Sett_time = 0.8;
zeta = 1;
w0 = 5.8/Sett_time;
p = -w0*zeta*10;

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
%%




L = inv(W0)*W0_tilde*[pd1-a1;pd2-a2];
L = eval(L);

% matrice di osservabilità in forma canonica
syms x 
polyA = charpoly(A,x)
polyA = coeffs(polyA)
a1 = polyA(2);
a2 = polyA(1);
a3 = 0;
W0_tilde = inv([1,0,0;a1,1,0;a2,a1,1]); %in alternativa W0_tilde = [1 0;-a1 1];

% calcolo dei coefficienti del polinomio desiderato



pd1 = 2*zeta*w0;
pd2 = w0^2;

L = inv(W0)*W0_tilde*[pd1-a1;pd2-a2];
L = eval(L);



