Ts = 0.005
y = load('y_davide2.mat').y
t = load('t_davide2.mat').t
u = load('u_davide2.mat').u
s=tf('s')
%% Filter signal
% With 10 seconds, and Ts = 0.005 we have 2000 samples, so 20 windowSize
% means is equal to 1.5%
windowSize = 25
b=(1/windowSize)*ones(1,windowSize)
a = 1
y_filtered = filter(b,a,y)
plot(t,y_filtered)
%% Secondo metodo

n = size(y_filtered)
S1 = 0
y_overline = 78.8

for i = 1:n-1
    S1 = S1 +(y_overline-y_filtered(i))*(t(i+1)-t(i));% definizione di integrale, f * \delta T, che suppongo essere sufficientemente piccolo
end

Q = trapz(t(1:length(t)),y_filtered(1:length(y_filtered)))
ext_area = y_overline*t(round(length(t)))-Q
S1 = ext_area/y_overline
mu = y_overline / u(1)
%%
% S1 = 5.0048 = T + tau
f=find(t<S1) % per ricavare quanto vale tau mi vado a vedere innanzitutto quando la t è pari a 5.0048, approssimo per difetto in questo caso
% i < 502
S2 = trapz(t(1:length(f)),y_filtered(1:length(f)))
T = S2*exp(1)/y_overline
tau = S1-T
G = mu/(1+s*T)*exp(-tau*s)

G_pade = mu/(1+s*T)* (1-0.5*tau*s)/(1+0.5*tau*s)

% rad/s to rpm
[y_pade,t_pade] = step(G_pade,t(length(t)))
[y_w,t_w] = step(G,t(length(t)))
y_w = y_w*12
y_pade = y_pade*12

plot(t,y_filtered,t_pade,y_pade,t_w,y_w);
legend('y filtered','G pade','G')

%% test da buttare

G1 = mu/(1+s*T)*exp(-(tau/10)*s)
G2 = G

% rad/s to rpm
[y1,t1] = step(G1,t(length(t)))
[y2,t2] = step(G2,t(length(t)))
y1 = y1*12
y2 = y2*12

figure;
plot(t,y_filtered)
hold on
plot(t1,y1)
plot(t2,y2)
legend('y filtered','G1_veloce','G')
hold off

%%

G_without_delay = G/s/9.5493
num = 6.567
den = [1.127 9.549 0]
[A,B,C,D] = tf2ss(num,den)
sys_with_delay = ss(A,B,C,D,'InputDelay',tau);
sys_pade = pade(sys_with_delay,1,0,0)
A = sys_pade.A
B = sys_pade.B
C = sys_pade.C
D = sys_pade.D
step(A,B,C,D)


G_pos = G_pade/s/9.5493
num = [-0.1507 6.567]
den = [0.02586 1.346 9.549 0]
[A,B,C,D] = tf2ss(num,den)

sys = ss(A,B,C,D);
Q = [0.0001 0 0 0;0 1 0 0;0 0 1 0; 0 0 0 1];
R = 0.01;
[K_tilde,S,e]=lqi(sys,Q,R,0);
K_tilde


