clear
clc
close all
tau = 6;
desplazamiento = 15;

ecg_100_0 = load('228m (0).mat');
ecg_100_1 = load('228m (1).mat');
ecg_100_2 = load('228m (2).mat');
ecg_100_3 = load('228m (3).mat');
ecg_100_4 = load('228m (4).mat');
ecg_100_5 = load('228m (5).mat');
ecg_100_6 = load('228m (6).mat');
ecg_100_7 = load('228m (7).mat');
ecg_100_8 = load('228m (8).mat');
ecg_100_9 = load('228m (9).mat');

signal_0 = ecg_100_0.val;
signal_1 = ecg_100_1.val;
signal_2 = ecg_100_2.val;
signal_3 = ecg_100_3.val;
signal_4 = ecg_100_4.val;
signal_5 = ecg_100_5.val;
signal_6 = ecg_100_6.val;
signal_7 = ecg_100_7.val;
signal_8 = ecg_100_8.val;
signal_9 = ecg_100_9.val;


%plot(signal)

load('continua-N6')
load('cmaxx.txt')
load('cmaxy.txt')
load('cminx.txt')
load('cminy.txt')





disp('Calculo de plano informacional')


opd_0=get_ordinal_pattern_dist(signal_0,tau,desplazamiento);
opd_1=get_ordinal_pattern_dist(signal_1,tau,desplazamiento);
opd_2=get_ordinal_pattern_dist(signal_2,tau,desplazamiento);
opd_3=get_ordinal_pattern_dist(signal_3,tau,desplazamiento);
opd_4=get_ordinal_pattern_dist(signal_4,tau,desplazamiento);
opd_5=get_ordinal_pattern_dist(signal_5,tau,desplazamiento);
opd_6=get_ordinal_pattern_dist(signal_6,tau,desplazamiento);
opd_7=get_ordinal_pattern_dist(signal_7,tau,desplazamiento);
opd_8=get_ordinal_pattern_dist(signal_8,tau,desplazamiento);
opd_9=get_ordinal_pattern_dist(signal_9,tau,desplazamiento);
 




[C_0 H_0]=get_mpr_complexity(opd_0);
[C_1 H_1]=get_mpr_complexity(opd_1);
[C_2 H_2]=get_mpr_complexity(opd_2);
[C_3 H_3]=get_mpr_complexity(opd_3);
[C_4 H_4]=get_mpr_complexity(opd_4);
[C_5 H_5]=get_mpr_complexity(opd_5);
[C_6 H_6]=get_mpr_complexity(opd_6);
[C_7 H_7]=get_mpr_complexity(opd_7);
[C_8 H_8]=get_mpr_complexity(opd_8);
[C_9 H_9]=get_mpr_complexity(opd_9);

C =[C_0 C_1 C_2 C_3 C_4 C_5 C_6 C_7 C_8 C_9];
H =[H_0 H_1 H_2 H_3 H_4 H_5 H_6 H_7 H_8 H_9];



 
disp('Proceso de graficacion')
plot(H,C,'+r','MarkerSize',14)
 axis([0 1 0 .55])
% tt=num2str([1:total]','%d');
% etiquetas=cellstr(tt);
 title('Informational Plane Complexity Entropy')
% text(H,C,etiquetas,'FontSize',10)

hold on
%plot(continua_N6(:,1),continua_N6(:,2),'r')

plot(cmaxx,cmaxy,'b')
hold on
plot(cminx,cminy,'b')
%%hold off

 valor_medio_C = mean(C);
 valor_medio_H = mean(H);
plot(valor_medio_H,valor_medio_C,'+g','MarkerSize',14)

figure(2)
boxplot(C,'Notch','on','Labels',{'Ccomplexity'})
title('Complexity','FontSize',14)

figure(3)
boxplot(H,'Notch','on','Labels',{'Shannon Entropy'})
title('Shannon Entropy','FontSize',14)


%print('Fig1.jpg','-djpeg')


