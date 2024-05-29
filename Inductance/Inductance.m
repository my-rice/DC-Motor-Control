pwmFreq = 2000;
Ts = 0.005;

%% Getting the L parameter

current = load('current.mat');
t = current.current.Time;
current = current.current.Data;

reference = load('reference.mat');
reference = reference.reference(:,:);

figure
plot(t,current)
title('Current')
xlabel('Time (s)')
ylabel('Current (A)')
legend('Current')


% Get the sample at time 5 and 5.005

% sample1_ind = find(t == 5);
% sample2_ind = find(t == 5.005);

% sample1 = current(sample1_ind);
% sample2 = current(sample2_ind);
% slope = (sample2 - sample1)/(5.005 - 5);
% tau = (sample2 - sample1)/slope;

tau = Ts;
R = 2;
L = tau*R;

