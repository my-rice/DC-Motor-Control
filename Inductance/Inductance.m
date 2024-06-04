pwmFreq = 2000;
Ts = 0.001;
Tf = Ts/2;
Tfs = Tf/20;
alpha = exp(-Tfs/Tf)

%% Getting the L parameter
% The reference is 0V in [0,3[ seconds, 12V in [3,6[ seconds and 0V in [6,9[
current = load('current.mat');
speed = load('speed.mat');
voltage = load('voltage.mat');

t = current.data.Time;
current = current.data.Data;
speed = speed.data.Data;
speed = speed*2*pi/60;
voltage = voltage.data.Data(:,:).';
current_original = current;

%% Compute the L parameter

% Take the values of speed and current in the interval ]3, 3.5]. The tension after 3 is 12V. The resistance is 2 Ohm. The Ke is 1.4543.
R = 2;
Ke = 1.4543; % Vs/rad

% apply a filter to the current
current = smooth(current, 0.03, 'loess');

% apply a filter to the speed
windowSize = 120;
b=(1/windowSize)*ones(1,windowSize);
a = 1;
speed = filter(b,a,speed);

% plot the current and the filtered current
figure
plot(t, current)
hold on
plot(t, current_original)
hold off
title('Current')
xlabel('Time (s)')
ylabel('Current (A)')
legend('Filtered current', 'Original current')


% Define the start and end times of each range
ranges = [2.9 3.07; 5.9 6.07; 8.9 9.07];
% Initialize an array to hold the L values for each range
L_ranges = zeros(size(ranges, 1), 1);

% Loop over each range
for i = 1:size(ranges, 1)
    L_values = [];
    % Select the data in the current range
    t_range = t(t >= ranges(i, 1) & t <= ranges(i, 2));
    current_range = current(t >= ranges(i, 1) & t <= ranges(i, 2));
    speed_range = speed(t >= ranges(i, 1) & t <= ranges(i, 2));
    voltage_range = voltage(t >= ranges(i, 1) & t <= ranges(i, 2));

    % Calculate L for the current range
    omega = speed_range;
    dI_dt = gradient(current_range, t_range);
    
    % Remove outliers from L values. Outliers are values that are 3 standard
    for j = 1:length(dI_dt)
        if dI_dt(j) ~= 0
        %if abs(dI_dt(j)) > 0.005
            L = (voltage_range(j) - R * current_range(j) - Ke * omega(j)) / dI_dt(j);
            L_values = [L_values L];
        end
    end
    L_ranges(i) = mean(L_values);
    variance = var(L_values)
end

L = mean(L_ranges)
