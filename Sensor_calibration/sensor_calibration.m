% Load the data from the file
y = load('Sensor_0Ampere.mat');

% Get the time and the data
t = y.data.Time;
y = y.data.Data(:,:);

%Vref = 3.3;
%y = y*Vref;

% get the average value of the sensor output
y_avg = mean(y);

plot(t,y)
title('Sensor output')
xlabel('Time (s)')
ylabel('Voltage (V)')
hold on
plot(t,ones(size(t))*y_avg)
legend('Sensor output','mean')