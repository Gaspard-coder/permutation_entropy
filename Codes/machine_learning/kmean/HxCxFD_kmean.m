function [D, C, means, stds, acc, F1, sensitivity, specificity] = HxCxFD_kmean(folder_healthy, folder_sick, m, t, k, k_max)
% =========================================================================
% Batch processes healthy (+1) and sick (-1) datasets, runs k-means in the 
% 3D feature space (H, C, FD), and characterizes clustering performance.
% =========================================================================
% Input:
%   - folder_healthy   : Path to folder containing healthy patient data
%   - folder_sick      : Path to folder containing sick patient data
%   - m, t             : Permutation entropy parameters
%   - k                : Number of clusters to be used in kmeans algorithm
%   - k_max            : Maximum timescale for Higuchi Fractal Dimension
%
% Output:
%   - D           : Distance matrix
%   - C           : Clusters coordinates (Nx3)
%   - means       : Means of distances to centroids
%   - stds        : Std deviations of distances to centroids
%   - acc         : Balanced accuracy [0, 1]
%   - F1          : F1-score [0, 1]
%   - sensitivity : True Positive Rate [0, 1]
%   - specificity : True Negative Rate [0, 1]
% =========================================================================

% Data extraction and computing via local helper function
Features_Healthy = extract_features(folder_healthy, m, t, k_max);
Features_Sick    = extract_features(folder_sick, m, t, k_max);

% Dataset labelling
X = [Features_Healthy; Features_Sick];            
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% k-means clustering with centroid extraction and distance matrix D
[idx, C, ~, D] = kmeans(X, k, 'Replicates', 5);

% Align clusters to ground truth: ensure Cluster 1 corresponds to Healthy (+1)
if mean(Y(idx == 1)) < mean(Y(idx == 2))
    idx = 3 - idx;       % Swap cluster indices 1 and 2
    C = C([2, 1], :);    % Swap centroids accordingly
    D = D(:, [2, 1]);    % Swap distance columns
end
Y_pred = (idx == 1) * 2 - 1; % Convert [1, 2] to [+1, -1]

% Performance Evaluation
TP = sum((Y == 1)  & (Y_pred == 1));
TN = sum((Y == -1) & (Y_pred == -1));
FP = sum((Y == -1) & (Y_pred == 1));
FN = sum((Y == 1)  & (Y_pred == -1));

sensitivity = TP / max(TP + FN, eps); % True Positive Rate
specificity = TN / max(TN + FP, eps); % True Negative Rate
acc         = 0.5 * (sensitivity + specificity); % Balanced Accuracy
F1          = 2 * TP / max(2*TP + FP + FN, eps);

fprintf('Accuracy: %.2f | F1-score: %.2f | Sensitivity: %.2f | Specificity: %.2f\n', ...
    acc, F1, sensitivity, specificity);

% Color definitions: Blue for Healthy (+1), Red for Sick (-1)
color_h = [0.1, 0.4, 0.8]; 
color_s = [0.8, 0.2, 0.2]; 

% Boolean masks
is_healthy = (Y == 1);
is_sick    = (Y == -1);
is_correct = (Y == Y_pred);

%% Figure 1: 3D HxCxFD Plane Classification
figure('Name', 'HxCxFD K-Means Classification');
hold on; grid on; view(3); % Enable 3D view

% Plot Healthy (+1) points
scatter3(X(is_healthy & is_correct, 1), X(is_healthy & is_correct, 2), X(is_healthy & is_correct, 3), 50, ...
    color_h, 'o', 'filled', 'DisplayName', 'Healthy (+1) - Correct');
scatter3(X(is_healthy & ~is_correct, 1), X(is_healthy & ~is_correct, 2), X(is_healthy & ~is_correct, 3), 70, ...
    color_h, 'x', 'LineWidth', 2, 'DisplayName', 'Healthy (+1) - Misclassified');

% Plot Sick (-1) points
scatter3(X(is_sick & is_correct, 1), X(is_sick & is_correct, 2), X(is_sick & is_correct, 3), 50, ...
    color_s, 'o', 'filled', 'DisplayName', 'Sick (-1) - Correct');
scatter3(X(is_sick & ~is_correct, 1), X(is_sick & ~is_correct, 2), X(is_sick & ~is_correct, 3), 70, ...
    color_s, 'x', 'LineWidth', 2, 'DisplayName', 'Sick (-1) - Misclassified');

% Plot Cluster Centroids in 3D
plot3(C(:, 1), C(:, 2), C(:, 3), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y', ...
    'LineWidth', 1.5, 'DisplayName', 'Centroids');

xlabel('Entropy (H)');
ylabel('Complexity (C)');
zlabel('Fractal Dimension (FD)');
title(sprintf('HxCxFD K-Means (Acc: %.1f%%, F1: %.2f, Sens: %.2f, Spec: %.2f)', acc * 100, F1,sensitivity,specificity));
legend('Location', 'best');
hold off;

%% Figure 2: Centroid Distance Analysis
figure('Name', 'Distance to Cluster Centroids');
hold on; grid on;

% Extract subgroup distance values
dist_H_to_C1 = D(is_healthy, 1); % Healthy points to Healthy Centroid
dist_H_to_C2 = D(is_healthy, 2); % Healthy points to Sick Centroid
dist_S_to_C1 = D(is_sick, 1);    % Sick points to Healthy Centroid
dist_S_to_C2 = D(is_sick, 2);    % Sick points to Sick Centroid

% Jitter x-positions for better point scatter visibility
x_H_C1 = 1 + (rand(size(dist_H_to_C1)) - 0.5) * 0.15;
x_H_C2 = 2 + (rand(size(dist_H_to_C2)) - 0.5) * 0.15;
x_S_C1 = 3 + (rand(size(dist_S_to_C1)) - 0.5) * 0.15;
x_S_C2 = 4 + (rand(size(dist_S_to_C2)) - 0.5) * 0.15;

% Plot individual data points
scatter(x_H_C1, dist_H_to_C1, 35, color_h, 'o', 'filled', ...
    'MarkerFaceAlpha', 0.5, 'DisplayName', 'Healthy Points');
scatter(x_H_C2, dist_H_to_C2, 35, color_h, 'o', 'filled', ...
    'MarkerFaceAlpha', 0.5, 'HandleVisibility', 'off');
scatter(x_S_C1, dist_S_to_C1, 35, color_s, 's', 'filled', ...
    'MarkerFaceAlpha', 0.5, 'DisplayName', 'Sick Points');
scatter(x_S_C2, dist_S_to_C2, 35, color_s, 's', 'filled', ...
    'MarkerFaceAlpha', 0.5, 'HandleVisibility', 'off');

% Compute Group Means and Standard Deviations
means = [mean(dist_H_to_C1), mean(dist_H_to_C2), mean(dist_S_to_C1), mean(dist_S_to_C2)];
stds  = [std(dist_H_to_C1),  std(dist_H_to_C2),  std(dist_S_to_C1),  std(dist_S_to_C2)];

% Plot Mean ± Std Error Bars
errorbar(1:4, means, stds, 'k', 'LineStyle', 'none', 'LineWidth', 2, ...
    'CapSize', 10, 'DisplayName', 'Mean \pm Std');
plot(1:4, means, 'kd', 'MarkerSize', 8, 'MarkerFaceColor', 'k', ...
    'HandleVisibility', 'off');

% Formatting Figure 2
xlim([0.5, 4.5]);
xticks(1:4);
xticklabels({ ...
    'Healthy \rightarrow C1 (Healthy)', ...
    'Healthy \rightarrow C2 (Sick)', ...
    'Sick \rightarrow C1 (Healthy)', ...
    'Sick \rightarrow C2 (Sick)'});
xtickangle(15);

ylabel('Euclidean Distance to Centroid');
title('Distances to Centroids by Ground Truth Class');
legend('Location', 'northeast');
hold off;

end

% Local Helper Function
function Feat = extract_features(folderPath, m, t, k_max)
    files = dir(fullfile(folderPath, '*.mat'));
    if isempty(files)
        error('No .mat files found in folder: %s', folderPath);
    end
    Feat = zeros(length(files), 3); % Expanded to 3 columns
    for i = 1:length(files)
        dataStruct = load(fullfile(folderPath, files(i).name));
        fn = fieldnames(dataStruct);
        signal = dataStruct.(fn{1});
        
        % Extract existing Entropy and Complexity
        [H_val, ~, C_val] = HXC_1_opti(signal, m, t); 
        
        % Extract Higuchi Fractal Dimension
        FD_val = Higuchi_FD(k_max, signal);
        
        Feat(i, :) = [H_val, C_val, FD_val];
    end
end