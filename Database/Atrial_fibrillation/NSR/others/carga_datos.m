ecg_100_0 = load('100m (0).mat')
ecg_100_1 = load('100m (1).mat')
ecg_100_2 = load('100m (2).mat')
ecg_100_3 = load('100m (3).mat')
ecg_100_4 = load('100m (4).mat')
ecg_100_5 = load('100m (5).mat')
ecg_100_6 = load('100m (6).mat')
ecg_100_7 = load('100m (7).mat')
ecg_100_8 = load('100m (8).mat')
ecg_100_9 = load('100m (9).mat')


ecg_101_0 = load('101m (0).mat')
ecg_101_1 = load('101m (1).mat')
ecg_101_2 = load('101m (2).mat')
ecg_101_3 = load('101m (3).mat')
ecg_101_4 = load('101m (4).mat')
ecg_101_5 = load('101m (5).mat')
ecg_101_6 = load('101m (6).mat')
ecg_101_7 = load('101m (7).mat')
ecg_101_8 = load('101m (8).mat')
ecg_101_9 = load('101m (9).mat')
ecg_101_10 = load('101m (10).mat')

ecg_103_0 = load('103m (0).mat')
ecg_103_1 = load('103m (1).mat')
ecg_103_2 = load('103m (2).mat')
ecg_103_3 = load('103m (3).mat')
ecg_103_4 = load('103m (4).mat')
ecg_103_5 = load('103m (5).mat')
ecg_103_6 = load('103m (6).mat')
ecg_103_7 = load('103m (7).mat')
ecg_103_8 = load('103m (8).mat')
ecg_103_9 = load('103m (9).mat')





plot(ecg_101_0.val,'r')
hold on
plot(ecg_100_0.val,'b')
%plot(ecg_101_2.val,'g')


data(:,1) = ecg_100_0.val;
data(:,2) = ecg_100_1.val;
data(:,3) = ecg_100_2.val;
data(:,4) = ecg_100_3.val;
data(:,5) = ecg_100_4.val;
data(:,6) = ecg_100_5.val;
data(:,7) = ecg_100_6.val;
data(:,8) = ecg_100_7.val;
data(:,9) = ecg_100_8.val;
data(:,10) = ecg_100_9.val;

[ U S V]=svd(data);    




