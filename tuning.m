Ts = 0.005

s=tf('s')

%% Secondo metodo

n = size(y)
S1 = 0
y_overline = 78
for i = 1:n-1
    S1 = S1 +(y_overline-y(i))*(t(i+1)-t(i));% definizione di integrale, f * \delta T, che suppongo essere sufficientemente piccolo
end
Q = trapz(t(1:length(t)),y(1:length(y)))
ext_area = y_overline*t(round(length(t)))-Q
S1 = ext_area/y_overline
mu = y_overline / u(1)
%%
% S1 = 5.0048 = T + tau
f=find(t<S1) % per ricavare quanto vale tau mi vado a vedere innanzitutto quando la t è pari a 5.0048, approssimo per difetto in questo caso
% i < 502
S2 = trapz(t(1:length(f)),y(1:length(f)))
T = S2*exp(1)/y_overline
tau = S1-T
G = mu/(1+s*T)*exp(-tau*s)
