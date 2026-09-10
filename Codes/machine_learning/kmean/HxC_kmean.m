function [acc, F1, sensitivity, specificity] = HxC_kmean(folder_healthy,folder_sick, m, t, k)
% Batch processes healthy and sick datasets, label them, run kmean algorithm
% in the HxC feature planand caracterize the efficienty of this clustering 
% compare to the training datas

% Data extraction and computing 
files_h = dir(fullfile(folder_healthy, '*.mat'));
if isempty(files_h)
    error('No .mat files found in folder: %s', folder_healthy);
end

Features_Healthy = zeros(length(files_h), 2);
for i = 1:length(files_h)
    filePath = fullfile(folder_healthy, files_h(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});
    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 
    Features_Healthy(i, :) = [H_val, C_val];
end

files_s = dir(fullfile(folder_sick, '*.mat'));
if isempty(files_s)
    error('No .mat files found in folder: %s', folder_sick);
end

Features_Sick = zeros(length(files_s), 2);
for i = 1:length(files_s)
    filePath = fullfile(folder_sick, files_s(i).name);
    dataStruct = load(filePath);
    fn = fieldnames(dataStruct);
    y = dataStruct.(fn{1});
    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 
    Features_Sick(i, :) = [H_val, C_val];
end

% Dataset labelling
X = [Features_Healthy; Features_Sick];            
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% k-means clustering with centroid extraction and multiple restarts
[idx, C] = kmeans(X, k, 'Replicates', 5);

% Align clusters to ground truth: ensure Cluster 1 corresponds to Healthy (+1)
if mean(Y(idx == 1)) < mean(Y(idx == 2))
    idx = 3 - idx; % Swap cluster indices 1 and 2
end
Y_pred = (idx == 1) * 2 - 1; % Convert [1, 2] to [+1, -1]

% Performance Evaluation
TP = sum((Y == 1) & (Y_pred == 1));
TN = sum((Y == -1) & (Y_pred == -1));
FP = sum((Y == -1) & (Y_pred == 1));
FN = sum((Y == 1) & (Y_pred == -1));

acc = 0.5*(TP/max(TP+FP,eps)+TN/max(TN+FN,eps)); %balanced accuracy
F1 = 2 * TP / max(2*TP + FP + FN, eps);
sensitivity = TP / max(TP + FP, eps);
specificity = TN / max(TN+FN,eps);


fprintf('Accuracy: %.2f |  F1-score: %.2f | sensitivity: %.2f | specificity: %.2f\n', acc, F1, sensitivity, specificity);

% Data Visualization
figure('Name', 'HxC K-Means Performance');
hold on; grid on;

% Color definitions: Blue for Healthy (+1), Red for Sick (-1)
color_h = [0.1, 0.4, 0.8]; 
color_s = [0.8, 0.2, 0.2]; 

% Classification boolean masks
is_healthy = (Y == 1);
is_sick    = (Y == -1);
is_correct = (Y == Y_pred);

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
plot(C(:, 1), C(:, 2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y', 'LineWidth', 1.5, 'DisplayName', 'Centroids');

xlabel('Entropy (H)');
ylabel('Complexity (C)');
title(sprintf('HxC K-Means Clustering (Acc: %.1f%%, F1: %.2f, sensitivity: %.2f, specificity: %.2f)', acc * 100, F1, sensitivity, specificity));
legend('Location', 'best');
hold off;

end
