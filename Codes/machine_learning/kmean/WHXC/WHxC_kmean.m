function [D, C_sqeuclidean, C_euclidean, means, stds, acc, F1, sensitivity, specificity] = WHxC_kmean(folder_healthy, folder_sick, m, t, k)
% =========================================================================
% Batch processes healthy (+1) and sick (-1) datasets, runs k-means in the
% WHxC (Weighted Permutation Entropy x Complexity) feature space.
% =========================================================================

% Data extraction and computing via local helper function
Features_Healthy = extract_features_wpe(folder_healthy, m, t);
Features_Sick    = extract_features_wpe(folder_sick, m, t);

% Dataset labelling
X = [Features_Healthy; Features_Sick];
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% k-means clustering with centroid extraction and distance matrix D
[idx, C_sqeuclidean, ~, D] = kmeans(X, k, 'Distance', 'sqeuclidean', ...
    'Replicates', 1, 'MaxIter', 100, 'Start', 'plus');

% Align clusters to ground truth: ensure Cluster 1 corresponds to Healthy (+1)
if mean(Y(idx == 1)) < mean(Y(idx == 2))
    idx = 3 - idx;                          % Swap cluster indices 1 and 2
    C_sqeuclidean = C_sqeuclidean([2, 1], :); % Swap sqeuclidean centroids
    D = D(:, [2, 1]);                       % Swap distance columns
end

% Compute Centroid Coordinates in Regular 2D Euclidean Space [Entropy (H), Complexity (C)]
% Note: for 'sqeuclidean', C_sqeuclidean is already the arithmetic mean,
% but we compute C_euclidean explicitly here for consistency.
C_euclidean = [mean(X(idx == 1, :), 1); ...
    mean(X(idx == 2, :), 1)];

Y_pred = (idx == 1) * 2 - 1; % Convert [1, 2] to [+1, -1]

% Performance Evaluation
TP = sum((Y == 1)  & (Y_pred == 1));
TN = sum((Y == -1) & (Y_pred == -1));
FP = sum((Y == -1) & (Y_pred == 1));
FN = sum((Y == 1)  & (Y_pred == -1));

sensitivity = TP / max(TP + FN, eps);
specificity = TN / max(TN + FP, eps);
acc         = 0.5 * (sensitivity + specificity);
F1          = 2 * TP / max(2*TP + FP + FN, eps);

% Print Performance Metrics & Euclidean Centroid Coordinates
fprintf('Accuracy: %.2f | F1-score: %.2f | Sensitivity: %.2f | Specificity: %.2f\n', ...
    acc, F1, sensitivity, specificity);
fprintf('Centroids (H, C):\n');
fprintf('  Cluster 1 (Healthy) : H = %.4f, C = %.4f\n', C_euclidean(1, 1), C_euclidean(1, 2));
fprintf('  Cluster 2 (Sick)    : H = %.4f, C = %.4f\n', C_euclidean(2, 1), C_euclidean(2, 2));

% Color definitions
color_h = [0.1, 0.4, 0.8];
color_s = [0.8, 0.2, 0.2];

% Boolean masks
is_healthy = (Y == 1);
is_sick    = (Y == -1);
is_correct = (Y == Y_pred);

%% Figure 1: WHxC Plane Classification
figure('Name', 'WHxC K-Means Classification');
hold on; grid on;

% Plot Healthy (+1) points
scatter(X(is_healthy & is_correct, 1), X(is_healthy & is_correct, 2), 50, ...
    color_h, 'o', 'filled', 'DisplayName', 'Healthy (+1) - Correct');
scatter(X(is_healthy & ~is_correct, 1), X(is_healthy & ~is_correct, 2), 70, ...
    color_h, 'x', 'LineWidth', 2, 'DisplayName', 'Healthy (+1) - Misclassified');

% Plot Sick (-1) points
scatter(X(is_sick & is_correct, 1), X(is_sick & is_correct, 2), 50, ...
    color_s, 'o', 'filled', 'DisplayName', 'Sick (-1) - Correct');
scatter(X(is_sick & ~is_correct, 1), X(is_sick & ~is_correct, 2), 70, ...
    color_s, 'x', 'LineWidth', 2, 'DisplayName', 'Sick (-1) - Misclassified');

% Plot Cluster Centroids
plot(C_euclidean(:, 1), C_euclidean(:, 2), 'kp', 'MarkerSize', 14, ...
    'MarkerFaceColor', 'y', 'LineWidth', 1.5, 'DisplayName', 'Centroids');

xlabel('Weighted Permutation Entropy (H)');
ylabel('Complexity (C)');
title(sprintf('WHxC K-Means (Acc: %.1f%%, F1: %.2f, Sens: %.2f, Spec: %.2f)', ...
    acc * 100, F1, sensitivity, specificity));
legend('Location', 'best');
hold off;

%% Figure 2: Centroid Distance Analysis
figure('Name', 'Distance to Cluster Centroids');
hold on; grid on;

dist_H_to_C1 = D(is_healthy, 1);
dist_H_to_C2 = D(is_healthy, 2);
dist_S_to_C1 = D(is_sick, 1);
dist_S_to_C2 = D(is_sick, 2);

x_H_C1 = 1 + (rand(size(dist_H_to_C1)) - 0.5) * 0.15;
x_H_C2 = 2 + (rand(size(dist_H_to_C2)) - 0.5) * 0.15;
x_S_C1 = 3 + (rand(size(dist_S_to_C1)) - 0.5) * 0.15;
x_S_C2 = 4 + (rand(size(dist_S_to_C2)) - 0.5) * 0.15;

scatter(x_H_C1, dist_H_to_C1, 35, color_h, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Healthy Points');
scatter(x_H_C2, dist_H_to_C2, 35, color_h, 'o', 'filled', 'MarkerFaceAlpha', 0.5, 'HandleVisibility', 'off');
scatter(x_S_C1, dist_S_to_C1, 35, color_s, 's', 'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Sick Points');
scatter(x_S_C2, dist_S_to_C2, 35, color_s, 's', 'filled', 'MarkerFaceAlpha', 0.5, 'HandleVisibility', 'off');

means_dist = [mean(dist_H_to_C1), mean(dist_H_to_C2), mean(dist_S_to_C1), mean(dist_S_to_C2)];
stds_dist  = [std(dist_H_to_C1),  std(dist_H_to_C2),  std(dist_S_to_C1),  std(dist_S_to_C2)];

errorbar(1:4, means_dist, stds_dist, 'k', 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10, 'DisplayName', 'Mean \pm Std');
plot(1:4, means_dist, 'kd', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');

xlim([0.5, 4.5]);
xticks(1:4);
xticklabels({ ...
    'Healthy \rightarrow Centroid 1 (Healthy)', ...
    'Healthy \rightarrow Centroid 2 (Sick)', ...
    'Sick \rightarrow Centroid 1 (Healthy)', ...
    'Sick \rightarrow Centroid 2 (Sick)'});
xtickangle(15);
ylabel('Squared Euclidean Distance to Centroid');
title('Distances to Centroids by Ground Truth Class');
legend('Location', 'northeast');
hold off;

end

% =========================================================================
% Local Helper Function: Feature Extraction
% =========================================================================
function Feat = extract_features_wpe(folderPath, m, t)
files = dir(fullfile(folderPath, '*.mat'));
if isempty(files)
    error('No .mat files found in folder: %s', folderPath);
end

Feat = zeros(length(files), 2);
for i = 1:length(files)
    dataStruct = load(fullfile(folderPath, files(i).name));
    fn = fieldnames(dataStruct);

    % Extract Normalized WPE (H) and MPR Complexity (C)
    [~, ~, H_val, ~, C_val] = WHXC(dataStruct.(fn{1}), m, t);
    Feat(i, :) = [H_val, C_val];
end
end
