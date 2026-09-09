function [SVMModel, Features_Healthy, Features_Sick, X, Y,labelled_values] = classify_H_C_LP_svm(folder_healthy, folder_sick, m, t, sample_frequency)
% CLASSIFY_H_C_LP_SVM Batch processes healthy and sick datasets to extract a
% 3D feature space: Permutation Entropy (H), MPR Complexity (C), and Lyapunov
% Exponent (LP). Trains a 3D Linear SVM with standardization, de-standardizes
% parameters, and visualizes the 3D separating plane and margins.


% Extract 3D Features (H, C, LP) for Healthy Patients
files_h = dir(fullfile(folder_healthy, '*.mat'));
if isempty(files_h)
    error('No .mat files found in folder: %s', folder_healthy);
end

Features_Healthy = zeros(length(files_h), 3);
for i = 1:length(files_h)
    filePath = fullfile(folder_healthy, files_h(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});

    % Feature 1 & 2: Permutation Entropy (H) & Complexity (C)
    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 

    % Feature 3: Largest Lyapunov Exponent (LP)
    lp_val = lyapunov_exponent(filePath, sample_frequency);

    Features_Healthy(i, :) = [H_val, C_val, lp_val];
end

% Extract 3D Features (H, C, LP) for Sick Patients
files_s = dir(fullfile(folder_sick, '*.mat'));
if isempty(files_s)
    error('No .mat files found in folder: %s', folder_sick);
end

Features_Sick = zeros(length(files_s), 3);
for i = 1:length(files_s)
    filePath = fullfile(folder_sick, files_s(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});

    % Feature 1 & 2: Permutation Entropy (H) & Complexity (C)
    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 

    % Feature 3: Largest Lyapunov Exponent (LP)
    lp_val = lyapunov_exponent(filePath, sample_frequency); 

    Features_Sick(i, :) = [H_val, C_val, lp_val];
end

% Dataset Assembly & 3D Linear SVM Training
X = [Features_Healthy; Features_Sick];            % Feature Matrix (N x 3)
Y = [ones(size(Features_Healthy, 1), 1); ...
    -ones(size(Features_Sick, 1), 1)];            % Labels: +1 (Healthy), -1 (Sick)

labelled_values = [X,Y];
% Train 3D Linear SVM with standardization across all 3 features
SVMModel = fitcsvm(X, Y, ...
    'KernelFunction', 'linear', ...
    'Standardize', true, ...
    'ClassNames', [1, -1]);

% De-Standardize 3D Parameters to Raw Feature Coordinates
w_std = SVMModel.Beta;  % 3x1 vector [w1; w2; w3] in z-score space
b_std = SVMModel.Bias;  % Scalar bias in z-score space
mu    = SVMModel.Mu;    % 1x3 mean vector [mu_H, mu_C, mu_LP]
sigma = SVMModel.Sigma; % 1x3 std vector [sigma_H, sigma_C, sigma_LP]

% Convert 3D weight vector and bias back to raw un-standardized coordinates:
% w_raw = w_std ./ sigma
% b_raw = b_std - sum(w_std .* mu ./ sigma)
w_raw = w_std ./ sigma';
b_raw = b_std - sum((w_std .* mu') ./ sigma');

% 3D Visualization (Data Points, Support Vectors & Hyperplane)
figure('Color', [1 1 1]); hold on; box on; grid on;

% Plot 3D feature points
scatter3(Features_Healthy(:,1), Features_Healthy(:,2), Features_Healthy(:,3), ...
    80, 'r', 'o', 'filled', 'DisplayName', 'Healthy (+1)');
scatter3(Features_Sick(:,1), Features_Sick(:,2), Features_Sick(:,3), ...
    80, 'b', 's', 'filled', 'DisplayName', 'Sick (-1)');

% Highlight Support Vectors
sv_idx = SVMModel.IsSupportVector;
scatter3(X(sv_idx, 1), X(sv_idx, 2), X(sv_idx, 3), ...
    160, 'k', 'o', 'LineWidth', 2, 'DisplayName', 'Support Vectors');

% Build 2D meshgrid over (H, C) plane to render the 3D surface
h_min = min(X(:,1)) - 0.02; h_max = max(X(:,1)) + 0.02;
c_min = min(X(:,2)) - 0.02; c_max = max(X(:,2)) + 0.02;
[H_grid, C_grid] = meshgrid(linspace(h_min, h_max, 30), linspace(c_min, c_max, 30));

% 3D Hyperplane equation: w1*H + w2*C + w3*LP + b = 0
% Solve for LP (Z-axis): LP = -(w1*H + w2*C + b) / w3
LP_plane = -(w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw) / w_raw(3);

% Render decision hyperplane surface
surf(H_grid, C_grid, LP_plane, 'FaceColor', [0.5 0.5 0.5], ...
    'FaceAlpha', 0.4, 'EdgeColor', 'k', 'EdgeAlpha', 0.3, ...
    'DisplayName', 'Decision Boundary Plane');

% 3D Margin equations: w1*H + w2*C + w3*LP + b = +1 and -1
LP_margin_plus  = (1 - (w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw)) / w_raw(3);
LP_margin_minus = (-1 - (w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw)) / w_raw(3);

surf(H_grid, C_grid, LP_margin_plus, 'FaceColor', 'r', ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none', 'DisplayName', 'Margin (+1)');
surf(H_grid, C_grid, LP_margin_minus, 'FaceColor', 'b', ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none', 'DisplayName', 'Margin (-1)');

% Formatting
xlabel('Normalized Permutation Entropy ($H$)', 'Interpreter', 'latex', 'FontSize', 11);
ylabel('MPR Complexity ($C$)', 'Interpreter', 'latex', 'FontSize', 11);
zlabel('Lyapunov Exponent ($LP$)', 'Interpreter', 'latex', 'FontSize', 11);
title(sprintf('3D Linear SVM Separation (m=%d, \\tau=%d, Fs=%d Hz)', m, t, sample_frequency));
legend('Location', 'best');
view(3); % Enable 3D perspective
rotate3d on;

% Dynamic axis limits
lp_min = min(X(:,3)) - 0.02;
lp_max = max(X(:,3)) + 0.02;
xlim([h_min h_max]);
ylim([c_min c_max]);
zlim([lp_min lp_max]);
hold off;
end
