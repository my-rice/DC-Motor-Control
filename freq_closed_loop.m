
% Estendiamo lo spazio di stato
K = K_tilde(1:3);
ki = -K_tilde(4);
Asys = [(A-B*K) -B*ki;C 0];
Bsys = [B*kr; -1]
%Bsys = [Btemp [0; 0; 0; -1]]
Csys = [C 0];

Gcc = tf(ss(Asys,Bsys,Csys,0))
    
bode(Gcc)