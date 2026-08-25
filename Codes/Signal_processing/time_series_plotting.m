data1 = load("subject_1_E.mat");
x1 = data1.G;
N1 = length(x1);
t1 = 1:N1;

data2 = load("subject_1_S.mat");
x2 = data2.G;
N2 = length(x2);
t2 = 1:N2;


plot(t1,x1,'DisplayName','Sick patient');
hold on
plot(t2,x2,'DisplayName','Healty patient');
legend
hold off
grid on;
