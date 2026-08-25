% Rectification of the bias in the Wavelet power spectrum with the data set
% (Nino3.dat) given by Torrence and Compo (1998).  This code is modified
% from wavetest.m, the example script provided by Torrence and Compo
% (1998), to demonstrate how to rectify the bias in wavelet power spectrum.
% This code generates Figure 4 of Liu et al. (2007).
%
% Yonggang Liu, 2006.4.12
%
% E-mail:  yliu18@gmail.com
% http://ocgweb.marine.usf.edu/~liu/wavelet.html
%
% References:
%
% Liu, Y., X.S. Liang, and R.H. Weisberg, 2007: Rectification of the bias
% in the wavelet power spectrum. Journal of Atmospheric and Oceanic 
% Technology, 24(12), 2093-2102.
% 
% Torrence, C., and G. P. Compo, 1998: A practical guide to wavelet 
% analysis. Bull. Amer. Meteor. Soc., 79, 61�78.
%========================================================================
% Here starts with the original file header:


%WAVETEST Example Matlab script for WAVELET, using NINO3 SST dataset
%
% See "http://paos.colorado.edu/research/wavelets/"
% Written January 1998 by C. Torrence
%
% Modified Oct 1999, changed Global Wavelet Spectrum (GWS) to be sideways,
%   changed all "log" to "log2", changed logarithmic axis on GWS to
clear
clc
close all
%Carga de la señal de entrada
lectura = 'prueba_tipo_chirp_2';
ecg_100_0 = load(strcat(lectura,'.','mat'));
%% ecg_100_0 = load('200m(0)denoised.mat');
sst = ecg_100_0.g;
%------------------------------------------------------ Computation

% normalize by standard deviation (not necessary, but makes it easier
% to compare with plot on Interactive Wavelet page, at
% "http://paos.colorado.edu/research/wavelets/plot/"
variance = std(sst)^2;
sst = (sst - mean(sst))/sqrt(variance) ;

n = length(sst);
%% WEL dt = 0.25 ;

dt = 1;

time = [0:length(sst)-1]*dt + dt ;  % construct time array

xlim = [0,1000];  % plotting range



pad = 1;      % pad the time series with zeroes (recommended)
dj = 0.25;    % this will do 4 sub-octaves per octave
s0 = 0.5*dt;    % this says start at a scale of 6 months
j1 = 7/dj;    % this says do 7 powers-of-two with dj sub-octaves each
lag1 = 0.72;  % lag-1 autocorrelation for red noise background
mother = 'Morlet';

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

% Scale-average between El Nino periods of 2--8 years
avg = find((scale >= 2) & (scale < 8));
Cdelta = 0.776;   % this is for the MORLET wavelet
scale_avg = (scale')*(ones(1,n));  % expand scale --> (J+1)x(N) array
scale_avg = power ./ scale_avg;   % [Eqn(24)]
scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(avg,:));   % [Eqn(24)]
scaleavg_signif = wave_signif(variance,dt,scale,2,lag1,-1,[2,256],mother);

% whos

%------------------------------------------------------ Plot:

  hight = 0.2;
  pos1a = [0.1 0.37 0.65 hight]; pos1b = [0.78 0.37 0.15 hight];
  pos2a = [0.1 0.14 0.65 hight]; pos2b = [0.78 0.14 0.15 hight];
  
  figure('visible','off'); orient tall;

%--- Contour plot wavelet power spectrum
  subplot('position',pos1a)
    levels = [0.0625,0.125,0.25,0.5,1,2,4,8,16] ;
    Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
    contour(time,log2(period),log2(power),log2(levels));  
    caxis([log2(levels(1)), log2(levels(end))]);

   % xlabel('Time (year)')
    ylabel('Period (years)')
    set(gca,'XLim',xlim(:))
    set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel',Yticks)
  % 95% significance contour, levels at -99 (fake) and 1 (95% signif)
    hold on
    [cs,h] = contour(time,log2(period),sig95,[-99,1],'k');
      set(h,'linewidth',1);    hold on;
      
  % cone-of-influence, anything "below" is dubious
   % plot(time,log2(coi),'k');  hold off
   
    ts = time;
    coi_area = [max(scale) coi max(scale) max(scale)];
    ts_area = [ts(1) ts ts(length(ts)) ts(1)];
    L = plot(ts_area,log2(coi_area),'k'); set(L,'linewidth',.3); hold on
    %hatch(L,45,'k','-',5,.3); hold on
    %hatch(L,135,'k','-',5,.3); hold on


  %--- Plot global wavelet spectrum
   subplot('position',pos1b)
     plot(global_ws,log2(period)); hold on;
     % plot(global_signif,log2(period),'--'); hold off
     % xlabel('Power (degC^2)')
    set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel','')
    set(gca,'XLim',[0,1.25*max(global_ws)])






%==================  Bias rectification start  =========================
 %--- divided by scales:
   for k=1:length(scale)
     powers(k,:) = power(k,:)/scale(k);
   end
   global_wss = global_ws./scale;
  c = powers;
  c = c(:);
%==================  Bias rectification end  =========================
  

%--- Contour plot wavelet power spectrum
   subplot('position',pos2a)
    levelss = 2.^[-6:2] ;
    Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
    contour(time,log2(period),log2(powers),log2(levelss));  
    caxis([log2(levelss(1)), log2(levelss(end))]);
    
    xlabel('Time (year)')
    ylabel('Period (years)')
    set(gca,'XLim',xlim(:))
    set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel',Yticks)
   % 95% significance contour, levels at -99 (fake) and 1 (95% signif)
    hold on
    [cs,h] = contour(time,log2(period),sig95,[-99,1],'k');     hold on
      set(h,'linewidth',1);    hold on;

   % cone-of-influence, anything "below" is dubious
    % plot(time,log2(coi),'k'); hold off
    L = plot(ts_area,log2(coi_area),'k'); set(L,'linewidth',.3); hold on
%    hatch(L,45,'k','-',5,.3); hold on
%    hatch(L,135,'k','-',5,.3); hold on

 %--- Plot global wavelet spectrum
  subplot('position',pos2b)
    plot(global_wss,log2(period))
    hold on
   % title('c) Global Wavelet Spectrum')
    set(gca,'YLim',log2([min(period),max(period)]), ...
	'YDir','reverse', ...
	'YTick',log2(Yticks(:)), ...
	'YTickLabel','')
    set(gca,'XLim',[0,1.25*max(global_wss)])
   %% xlabel('Global')
    xlabel('Time Averaged')

print -djpeg wavelet_test_2.jpg;

 close all;
 
