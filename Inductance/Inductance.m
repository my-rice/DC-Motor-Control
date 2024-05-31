pwmFreq = 2000;
Ts = 0.005;
Ts = 0.005;
Tfs = 0.00025;
alpha = exp(-Tfs/Ts)

%% Getting the L parameter
% The reference is 0V in [0,3[ seconds, 12V in [3,6[ seconds and 0V in [6,9[
current = load('current.mat');
t = current.data.Time;
current = current.data.Data;


figure
plot(t,current)
title('Current')
xlabel('Time (s)')
ylabel('Current (A)')
legend('Current')

% At 3 second it is (3,0.0695192)
% The peak is (3.04,1.69866)

value_at_63 = 0.6321 * (1.69866-0.0695192)

m = (1.69866-0.0695192)/(3.04-3);
q = 1.69866-m*3.04;
t = (value_at_63 - q)/m

tau = t - 3

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

