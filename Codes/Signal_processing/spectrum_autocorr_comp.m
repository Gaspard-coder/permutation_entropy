function spectrum_autocorr_comp(file1, file2)
% =========================================================================
% Loads two .mat files containing 1D time series and plots their 
% Power Spectral Density (PSD) and Autocorrelation functions both 
% superimposed and in separated 2x2 subplots with synchronized y-axes.
%
% Input:
%     file1 : path to the first .mat file
%     file2 : path to the second .mat file
% =========================================================================

% Load data from .mat files
data1 = load(file1);
cells1 = struct2cell(data1);
x1 = double(cells1{1}(:));

data2 = load(file2);
cells2 = struct2cell(data2);
x2 = double(cells2{1}(:));

% Extract file labels for display
[~, name1] = fileparts(file1);
[~, name2] = fileparts(file2);

% --- 1. Compute Autocorrelation ---
[autocorr1, lags1] = xcorr(x1 - mean(x1), 'coeff');
[autocorr2, lags2] = xcorr(x2 - mean(x2), 'coeff');

% --- 2. Compute Power Spectral Density (FFT) ---
N1 = length(x1);
fft1 = fft(x1 - mean(x1));
psd1 = (abs(fft1).^2) / N1;
f1 = (0:floor(N1/2)) / N1;
psd1_db = 10*log10(psd1(1:floor(N1/2)+1) + eps);

N2 = length(x2);
fft2 = fft(x2 - mean(x2));
psd2 = (abs(fft2).^2) / N2;
f2 = (0:floor(N2/2)) / N2;
psd2_db = 10*log10(psd2(1:floor(N2/2)+1) + eps);

% Common y-limits for PSD
psd_min = min([psd1_db; psd2_db]);
psd_max = max([psd1_db; psd2_db]);
psd_limits = [psd_min, psd_max + 0.05 * abs(psd_max)]; % small margin on top

% --- 3. Figure 1: Superimposed Comparison ---
figure('Color', 'w', 'Name', 'Superimposed Comparison', 'Position', [100, 500, 1000, 420]);

subplot(1, 2, 1);
plot(f1, psd1_db, 'b', 'LineWidth', 1.2); hold on;
plot(f2, psd2_db, 'r', 'LineWidth', 1.2); hold off;
grid on;
xlabel('Normalized Frequency (\times \pi rad/sample)');
ylabel('Power Spectral Density (dB)');
title('Power Spectral Density (PSD) - Superimposed');
legend(name1, name2, 'Interpreter', 'none', 'Location', 'best');

subplot(1, 2, 2);
plot(lags1, autocorr1, 'b', 'LineWidth', 1.2); hold on;
plot(lags2, autocorr2, 'r', 'LineWidth', 1.2); hold off;
grid on;
xlabel('Lag (samples)');
ylabel('Autocorrelation coefficient');
title('Autocorrelation Function - Superimposed');
legend(name1, name2, 'Interpreter', 'none', 'Location', 'best');

% --- 4. Figure 2: Separated Plots (2x2 Grid) ---
figure('Color', 'w', 'Name', 'Separated Signals', 'Position', [150, 100, 1000, 700]);

% PSD File 1
ax1 = subplot(2, 2, 1);
plot(f1, psd1_db, 'b', 'LineWidth', 1.2);
grid on;
ylim(psd_limits);
xlabel('Normalized Frequency (\times \pi rad/sample)');
ylabel('PSD (dB)');
title(sprintf('PSD: %s', name1), 'Interpreter', 'none');

% PSD File 2
ax2 = subplot(2, 2, 2);
plot(f2, psd2_db, 'r', 'LineWidth', 1.2);
grid on;
ylim(psd_limits);
xlabel('Normalized Frequency (\times \pi rad/sample)');
ylabel('PSD (dB)');
title(sprintf('PSD: %s', name2), 'Interpreter', 'none');

% Autocorrelation File 1
subplot(2, 2, 3);
plot(lags1, autocorr1, 'b', 'LineWidth', 1.2);
grid on;
xlabel('Lag (samples)');
ylabel('Autocorrelation');
title(sprintf('Autocorrelation: %s', name1), 'Interpreter', 'none');

% Autocorrelation File 2
subplot(2, 2, 4);
plot(lags2, autocorr2, 'r', 'LineWidth', 1.2);
grid on;
xlabel('Lag (samples)');
ylabel('Autocorrelation');
title(sprintf('Autocorrelation: %s', name2), 'Interpreter', 'none');

% Link y-axes for PSD plots interactively
linkaxes([ax1, ax2], 'y');

end