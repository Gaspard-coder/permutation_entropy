function [SVMModel, H_healthy, H_sick] = classify_H_svm(folder_healthy, folder_sick, m, t)
% CLASSIFY_H_SVM Batch processes healthy and sick glucose datasets,
% computes normalized permutation entropy (H), trains a 1D Linear SVM
% with standardization, and visualizes the optimal hyperplane and margins
% in raw feature space.

% Extract Features from Healthy Patient Files
files_h = dir(fullfile(folder_healthy, '*.mat'));
if isempty(files_h)
    error('No .mat files found in folder: %s', folder_healthy);
end

H_healthy = zeros(length(files_h), 1);
for i = 1:length(files_h)
    filePath = fullfile(folder_healthy, files_h(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1}); % Dynamically extract the signal array

    % Extract normalized permutation entropy (3rd output argument)
    [~, ~, H_healthy(i)] = permentropy_opti(y, m, t); %[cite: 1]
end


% Extract Features from Sick Patient Files
files_s = dir(fullfile(folder_sick, '*.mat'));
if isempty(files_s)
    error('No .mat files found in folder: %s', folder_sick);
end

H_sick = zeros(length(files_s), 1);
for i = 1:length(files_s)
    filePath = fullfile(folder_sick, files_s(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1}); % Dynamically extract the signal array

    % Extract normalized permutation entropy (3rd output argument)
    [~, ~, H_sick(i)] = permentropy_opti(y, m, t); %[cite: 1]
end

% Dataset Assembly & Standardized Linear SVM
X = [H_healthy; H_sick];                     % Feature Vector (N x 1)
Y = [ones(size(H_healthy)); -ones(size(H_sick))]; % Labels: +1 (Healthy), -1 (Sick)

% Enable standardization for numerical stability and robust margin calculation
SVMModel = fitcsvm(X, Y, ...
    'KernelFunction', 'linear', ...
    'Standardize', true, ...
    'ClassNames', [1, -1]);

% Un-Standardize Parameters to Raw Feature Coordinates
w_std = SVMModel.Beta;  % Weight in standardized z-score space
b_std = SVMModel.Bias;  % Bias in standardized z-score space
mu    = SVMModel.Mu;    % Mean of feature vector X
sigma = SVMModel.Sigma; % Standard deviation of feature vector X

% Transform parameters back to the original H domain:
% w_raw = w_std / sigma
% b_raw = b_std - (w_std * mu / sigma)
w_raw = w_std / sigma;
b_raw = b_std - (w_std * mu / sigma);

% Decision boundary equation in raw space: w_raw * x + b_raw = 0
x_hyperplane   = -b_raw / w_raw;

% Margin equations in raw space: w_raw * x + b_raw = +1 and -1
x_margin_plus  = (1 - b_raw) / w_raw;   % Boundary for class +1
x_margin_minus = (-1 - b_raw) / w_raw;  % Boundary for class -1

% Visualization
figure('Color', [1 1 1]);
hold on; box on; grid on;

% Plot feature distributions along discrete class levels (+1 and -1)
plot(H_healthy, ones(size(H_healthy)), 'ro', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'Healthy (+1)');
plot(H_sick, -ones(size(H_sick)), 'bs', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'Sick (-1)');

% Highlight Support Vectors (plotted at their true class labels)
sv_idx = SVMModel.IsSupportVector;
plot(X(sv_idx), Y(sv_idx), 'ko', 'MarkerSize', 13, ...
    'LineWidth', 2, 'DisplayName', 'Support Vectors');

% Plot Decision Boundary and Margin Thresholds as vertical lines
xline(x_hyperplane, 'k-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Decision Boundary (H = %.4f)', x_hyperplane));
xline(x_margin_plus, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Margin (+1)');
xline(x_margin_minus, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Margin (-1)');

% Formatting
xlabel('Normalized Permutation Entropy (H)', 'FontSize', 12);
ylabel('Assigned Class Label', 'FontSize', 12);
title(sprintf('1D Linear SVM Separation (m = %d, \\tau = %d)', m, t), 'FontSize', 13);
ylim([-2 2]);
yticks([-1 1]);
yticklabels({'Sick (-1)', 'Healthy (+1)'});
legend('Location', 'best');

% Dynamic X-axis bounds around raw data range
h_min = min(X) - 0.03;
h_max = max(X) + 0.03;
xlim([h_min h_max]);

hold off;
end