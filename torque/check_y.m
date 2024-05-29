
y1 = load('run1.mat');
y2 = load('run2.mat');

t = y1.data.Time;

y1 = y1.data.Data;
y2 = y2.data.Data;

figure
plot(t,y1)

hold on
plot(t,y2)

title('Current')
xlabel('Time (s)')
ylabel('Current (A)')
legend('Run 1','Run 2')
