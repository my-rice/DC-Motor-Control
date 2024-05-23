Ts = 0.005

s=tf('s')
%% Filter signal
% With 10 seconds, and Ts = 0.005 we have 2000 samples, so 20 windowSize
% means is equal to 1.5%
windowSize = 30
b=(1/windowSize)*ones(1,windowSize)
a = 1
y_filtered = filter(b,a,y)
plot(t,y_filtered)
%% Secondo metodo

n = size(y_filtered)
S1 = 0
y_overline = 80.71
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

%% Approssimazione di Padè
G_pade = (mu/(1+s*T))*((1-0.5*tau*s)/(1+0.5*tau*s))
G_with_integration = G_pade/s
% [num,den]=tfdata(G_pade)
%num = [0 -0.1697 6.7333]
%den = [0.0030 0.1436 1]
num = [0 0 -0.2075 6.7258]
den = [0.0034 0.1395 1 0]
[A,B,C,D]=tf2ss(num,den)
% Dovrebbe funzionare fino a w circa 1/tau, ovvero 19.8410 nel nostro caso
%https://lpsa.swarthmore.edu/Representations/SysRepTransformations/TF2SS.html#:~:text=Probably%20the%20most%20straightforward%20method,is%20not%20important%20to%20us.
%H(s) = Y(s)/U(s)=(b0s^n+b1s^{n-1}+...+b_{n-1}s+b_n)/(s^n+a_1s^{n-1}+...+a_{n-1}s+a_n)
% A = [0 1 0 ... 0; 0 0 1 ... 0; .....,; 0 0 0... 1; -a_n -a_{n-1} -a_{n-2}
% ... -a1]
% B = [0;0;...;1] C = [(b_n-a_nb_0) (b_{n-1}-a_{n-1}b_0) ... (b_2-a_2b_0)
% (b_1-a_1b_0)] D= b_0
% b0 = 6.733
% b1 = -0.1697
% a0=1
% a1=0.1436
% a2 = 0.002983
% A = [0 1; -a0/a2 -a1/a2]
% B = [0; 1/a2]
% C = [b0-(b1*a0)/a2 b1-(b1*a1)/a2]
% D=b0
