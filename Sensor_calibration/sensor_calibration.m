% Load the data from the file
y = load('Sensor_0Ampere.mat');

% Get the time and the data
t = y.data.Time;
y = y.data.Data(:,:);

%Vref = 3.3;
%y = y*Vref;

% get the average value of the sensor output
y_avg = mean(y);

% plot the sensor output
plot(t,y)
title('Sensor output')
xlabel('Time (s)')
ylabel('Voltage (V)')
hold on

% plot the average value
plot(t,y_avg*ones(size(t)),'LineWidth',2)
legend('Sensor output','mean')
% set x and y limits
xlim([0 180])
ylim([2.54 2.57])