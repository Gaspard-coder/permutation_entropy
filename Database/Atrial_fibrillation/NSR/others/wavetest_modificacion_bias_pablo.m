% =========================================================================
% Analisis mediante onditas de ECGs.
% By Walter Legnani.
% Signals and Images Processing Centre
% UTN FRBA.
% Based uppon "http://paos.colorado.edu/research/wavelets/"
% By C. Torrence and Compo
% =========================================================================
% Modified Oct 1999, changed Global Wavelet Spectrum (GWS) to be sideways,
%   changed all "log" to "log2", changed logarithmic axis on GWS to
%   a normal axis.
%clear
clc
close all
%Carga de la señal de entrada
%lectura = '100m (1)';%'100m (0)';
%ecg_100_0 = load(strcat(lectura,'.','mat'));
%%ecg_100_0 = load('200m(0)denoised.mat');
%sst = ecg_100_0.val;
sst = H_30;
% Seccion de Calculos 
% normalize by standard deviation (not necessary, but makes it easier
% to compare with plot on Interactive Wavelet page, at
% "http://paos.colorado.edu/research/wavelets/plot/"
variance = std(sst)^2;
sst = (sst - mean(sst))/sqrt(variance) ;

n = length(sst);
%% dt = 0.25 ;
dt = 10/3600 ;

%%time = [0:length(sst)-1]*dt + 1871.0 ;  % construct time array
time = [0:length(sst)-1]*dt + dt ;  % construct time array

%% xlim = [1870,2000];  % plotting range
xlim = [0,10];  % plotting range


pad = 1;      % pad the time series with zeroes (recommended)
dj = 0.25;    % this will do 4 sub-octaves per octave
s0 = 5*dt;    % this says start at a scale of 6 months
j1 = 7/dj;    % this says do 7 powers-of-two with dj sub-octaves each
lag1 = 0.72;  % lag-1 autocorrelation for red noise background
mother = 'Morlet';%'Paul'%'DOG'%'Morlet';

% Wavelet transform:
[wave,period,scale,coi] = wavelet(sst,dt,pad,dj,s0,j1,mother);
power = (abs(wave)).^2 ;        % compute wavelet power spectrum





% Significance levels: (variance=1 for the normalized SST)
[signif,fft_theor] = wave_signif(1.0,dt,scale,0,lag1,-1,-1,mother);
sig95 = (signif')*(ones(1,n));  % expand signif --> (J+1)x(N) array
sig95 = power ./ sig95;         % where ratio > 1, power is significant

% Global wavelet spectrum & significance levels:
global_ws = variance*(sum(power')/n);   % time-average over all times
dof = n - scale;  % the -scale corrects for padding at edges
global_signif = wave_signif(variance,dt,scale,1,lag1,-1,dof,mother);
%%global_signif = wave_signif(variance,dt,scale,0,lag1,-1,dof,mother);

% Scale-average between El Nino periods of 2--8 years
avg = find((scale >= 2) & (scale < 8));
Cdelta = 0.776;   % this is for the MORLET wavelet
scale_avg = (scale')*(ones(1,n));  % expand scale --> (J+1)x(N) array
scale_avg = power ./ scale_avg;   % [Eqn(24)]
scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(avg,:));   % [Eqn(24)]
%% WEL scaleavg_signif = wave_signif(variance,dt,scale,0,lag1,-1,[2,7.9],mother);
scaleavg_signif = wave_signif(variance,dt,scale,0,lag1,.99,[0.02,2.5],mother);


%==================  Bias rectification start  =========================
 %--- divided by scales:
   for k=1:length(scale)
     powers(k,:) = power(k,:)/scale(k);
   end
   global_wss = global_ws./scale;
  c = powers;
  c = c(:);
%==================  Bias rectification end  =========================



%% WEL whos

% Plotting Seccion

%--- Plot ECG Signal
subplot('position',[0.1 0.75 0.65 0.2])
%% WEL figure(1)
%% WEL subplot(2,1,1)
plot(time,sst)
set(gca,'XLim',xlim(:))
xlabel('Time (s)')
ylabel('ECG')
title('a) ECG Signal')
hold off

%--- Contour plot wavelet power spectrum
subplot('position',[0.1 0.37 0.65 0.28])
%% WEL figure(2)
%WEL subplot(2,1,2)
levels = [0.0625,0.125,0.25,0.5,1,2,4,8,12,16] ;
Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
contour(time,log2(period),log2(power),log2(levels));  %*** or use 'contourfill'
%imagesc(time,log2(period),log2(power));  %*** uncomment for 'image' plot
xlabel('Time (s)')
ylabel('Period (s)')
title('b) ECG Wavelet Power Spectrum')
set(gca,'XLim',xlim(:))
set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel',Yticks)
% 95% significance contour, levels at -99 (fake) and 1 (95% signif)
hold on
[cs h]=contour(time,log2(period),sig95,[-99,1],'k');
set(h,'linewidth',2)
hold on
% cone-of-influence, anything "below" is dubious
plot(time,log2(coi),'k')
hold off


%--- Plot global wavelet spectrum
subplot('position',[0.77 0.37 0.2 0.28])
%% WEL figure(3)
%% WEL subplot(2,1,2)
plot(global_wss,log2(period))
hold on
plot(global_signif,log2(period),'--')
hold off
xlabel('Power (ECG^2)')
title('c) Global Wavelet Spectrum')
set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel','')
set(gca,'XLim',[0,1.20*max(global_wss)])

%--- Plot 2--8 yr scale-average time series
subplot('position',[0.1 0.07 0.65 0.2])
%% WEL figure(4)
plot(time,scale_avg)
set(gca,'XLim',xlim(:))
xlabel('Time (s)')
ylabel('Avg variance (ECG^2)')
title('d) 2-8 yr Scale-average Time Series')
hold on
xlim = 1:29;
%% WEL plot(xlim,scaleavg_signif'+[0,0],'--')
plot(xlim,scaleavg_signif,'--')
hold off


%%subplot('position',[0.1 0.37 0.65 0.28])
figure(2)
xlim = [1.4,2.7];   % plotting range 0-10
subplot(2,1,1)
plot(time,sst)
set(gca,'XLim',xlim(:))
xlabel('Time (s)')
ylabel('ECG')
title('a) ECG Signal')
hold off

xlim = [1.4,2.7]%[0,10];  % plotting range
subplot(2,1,2)
levels = [0.0625,0.125,0.25,0.5,1,2,4,8,12,16] ;
Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
contour(time,log2(period),log2(power),log2(levels));  %*** or use 'contourfill'
%imagesc(time,log2(period),log2(power));  %*** uncomment for 'image' plot
xlabel('Time (s)')
ylabel('Period (s)')
title('b) ECG Wavelet Power Spectrum')
set(gca,'XLim',xlim(:))
set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel',Yticks)
% 95% significance contour, levels at -99 (fake) and 1 (95% signif)
hold on
contour(time,log2(period),sig95,[-99,1],'k');
hold on
% cone-of-influence, anything "below" is dubious
plot(time,log2(coi),'k')
hold off




%% WEL print(strcat(lectura,'.','jpg'),'-djpeg'





% end of code