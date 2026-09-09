function [SVMModel, Features_Healthy, Features_Sick] = classify_H_C_svm(folder_healthy, folder_sick, m, t)
% CLASSIFY_H_C_SVM Processes healthy and sick datasets to compute the
% Complexity-Entropy Causality plane coordinates (H and C) and trains
% a 2D Linear SVM to find the optimal separating hyperplane.

% Extract 2D Features (H and C) for Healthy Patients
files_h = dir(fullfile(folder_healthy, '*.mat'));
if isempty(files_h)
    error('No .mat files found in folder: %s', folder_healthy);
end

% Preallocate [H, C] matrix
Features_Healthy = zeros(length(files_h), 2);
for i = 1:length(files_h)
    filePath = fullfile(folder_healthy, files_h(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});

    % Extract Normalized Permutation Entropy (pe) and MPR Complexity (Comp_JS)
    [H_val, ~, C_val] = HXC_1_opti(y, m, t);
    Features_Healthy(i, :) = [H_val, C_val];
end

% same for Sick Patients
files_s = dir(fullfile(folder_sick, '*.mat'));
if isempty(files_s)
    error('No .mat files found in folder: %s', folder_sick);
end

% Preallocate [H, C] matrix
Features_Sick = zeros(length(files_s), 2);
for i = 1:length(files_s)
    filePath = fullfile(folder_sick, files_s(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});

    % Extract Normalized Permutation Entropy (pe) and MPR Complexity (Comp_JS)
    [H_val, ~, C_val] = HXC_1_opti(y, m, t);
    Features_Sick(i, :) = [H_val, C_val];
end

% Dataset Assembly & SVM Optimization
X = [Features_Healthy; Features_Sick];            % Feature Matrix (N x 2)
Y = [ones(size(Features_Healthy, 1), 1); ...
    -ones(size(Features_Sick, 1), 1)];            % Labels: +1 (Healthy), -1 (Sick)

% Train 2D linear SVM
SVMModel = fitcsvm(X, Y, ...
    'KernelFunction', 'linear', ...
    'Standardize', true, ...
    'ClassNames', [1, -1]);


% Un-Standardize Parameters for Raw Coordinates Plotting
w_std = SVMModel.Beta;     % 2x1 weights in standardized space
b_std = SVMModel.Bias;     % Scalar bias in standardized space
mu    = SVMModel.Mu;       % 1x2 mean vector [mu_H, mu_C]
sigma = SVMModel.Sigma;    % 1x2 std vector [sigma_H, sigma_C]

% Convert weights and bias back to raw un-standardized feature space:
% w_raw = w_std / sigma
% b_raw = b_std - sum(w_std * mu / sigma)
w_raw = w_std ./ sigma';
b_raw = b_std - sum((w_std .* mu') ./ sigma');

% Plotting
figure('Color', [1 1 1]); hold on; box on; grid on;

% Plot Feature Distributions
plot(Features_Healthy(:,1), Features_Healthy(:,2), 'ro', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'Healthy (+1)');
plot(Features_Sick(:,1), Features_Sick(:,2), 'bs', 'LineWidth', 1.5, ...
    'MarkerSize', 8, 'DisplayName', 'Sick (-1)');

% Highlight Support Vectors
sv_idx = SVMModel.IsSupportVector;
plot(X(sv_idx, 1), X(sv_idx, 2), 'ko', 'MarkerSize', 13, ...
    'LineWidth', 2, 'DisplayName', 'Support Vectors');

% Generate X-axis values spanning feature domain
h_min = min(X(:,1)) - 0.02;
h_max = max(X(:,1)) + 0.02;
h_line = linspace(h_min, h_max, 100);

% Decision boundary: w1_raw*H + w2_raw*C + b_raw = 0
c_hyperplane = -(w_raw(1)*h_line + b_raw) / w_raw(2);
plot(h_line, c_hyperplane, 'k-', 'LineWidth', 2, 'DisplayName', 'Decision Boundary');

% Margins: w1_raw*H + w2_raw*C + b_raw = +1 and -1
c_margin_plus  = (1 - (w_raw(1)*h_line + b_raw)) / w_raw(2);
c_margin_minus = (-1 - (w_raw(1)*h_line + b_raw)) / w_raw(2);
plot(h_line, c_margin_plus, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Margin (+1)');
plot(h_line, c_margin_minus, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Margin (-1)');

% Formatting
xlabel('Normalized Permutation Entropy ($H$)', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('MPR Complexity ($C$)', 'Interpreter', 'latex', 'FontSize', 12);
title(sprintf('2D Linear SVM on Complexity-Entropy Plane (m=%d, \\tau=%d)', m, t));
legend('Location', 'best');

% Set plot limits dynamically around actual data
c_min = min(X(:,2)) - 0.02;
c_max = max(X(:,2)) + 0.02;
xlim([h_min h_max]);
ylim([c_min c_max]);
hold off;
end