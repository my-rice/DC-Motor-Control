
matlab_data = torque_matlab.Data
matlab_time = torque_matlab.Time

dc_time = dc(:,1)*0.0010;
dc_output = dc(:,3);
dc_reference = dc(:,7);

% delete from dc data the first second of data
% dc_time = dc_time(25:end);
% dc_output = dc_output(25:end);
% dc_reference = dc_reference(25:end);

dc_time = dc_time - dc_time(1);

figure(1)
plot(matlab_time, matlab_data)
hold on
plot(dc_time, dc_output)
plot(dc_time, dc_reference)
hold off
title('Torque')
xlabel('Time (s)')
ylabel('Torque (N*m)')
legend('C Matlab', 'C Direct Coding', 'Reference')

