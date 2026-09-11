function [acc, F1, sensitivity, specificity] = check_centroids(folder_healthy, folder_sick, centroid_healthy, centroid_sick, m, t)
% =========================================================================
% CHECK_CENTROIDS Evaluates nearest-centroid classification performance
% on dataset features against pre-computed class centroids.
% =========================================================================
% Input:
%   - folder_healthy   : Path to folder containing healthy patient data
%   - folder_sick      : Path to folder containing sick patient data
%   - centroid_healthy : (x,y) coordinates of the healthy centroid
%   - centroid_sick    : (x,y) coordinates of the sick centroid
%   - m, t             : Parameters for feature extraction
%
% Output:
%   - acc         : Balanced accuracy [0, 1]
%   - F1          : F1-score [0, 1]
%   - sensitivity : True Positive Rate [0, 1]
%   - specificity : True Negative Rate [0, 1]
%
% Example of use: check_centroids('Database/diabet/CGMacros/resampled_15/NDBT2_dexcom','Database/diabet/CGMacros/resampled_15/DBT2_dexcom',[0.9518,0.0791],[0.8303,0.2189],5,2);
% =========================================================================

% Ensure centroids are formatted as row vectors
centroid_healthy = centroid_healthy(:)';
centroid_sick    = centroid_sick(:)';

% Data extraction via local/external helper function
Features_Healthy = extract_features(folder_healthy, m, t);
Features_Sick    = extract_features(folder_sick, m, t);

% Dataset labelling (+1 = Healthy, -1 = Sick)
X = [Features_Healthy; Features_Sick];            
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% Verify feature dimension alignment with centroids
if size(X, 2) ~= size(centroid_healthy, 2) || size(X, 2) ~= size(centroid_sick, 2)
    error('Feature dimension (%d) does not match centroid dimensions.', size(X, 2));
end

% Compute squared Euclidean distance to each centroid
dist_healthy = sum((X - centroid_healthy).^2, 2);
dist_sick    = sum((X - centroid_sick).^2, 2);

% Nearest-centroid classification (+1 if closer to healthy, -1 if closer to sick)
Y_pred = ones(size(Y));
Y_pred(dist_sick < dist_healthy) = -1;

% Performance Evaluation (Identical formulation to HxC_kmean)
TP = sum((Y == 1)  & (Y_pred == 1));
TN = sum((Y == -1) & (Y_pred == -1));
FP = sum((Y == -1) & (Y_pred == 1));
FN = sum((Y == 1)  & (Y_pred == -1));

sensitivity = TP / max(TP + FN, eps);                 % True Positive Rate
specificity = TN / max(TN + FP, eps);                 % True Negative Rate
acc         = 0.5 * (sensitivity + specificity);      % Balanced Accuracy
F1          = 2 * TP / max(2*TP + FP + FN, eps);       % F1-score


%% =========================================================================
% LOG SECTION
% =========================================================================
fprintf('\n================ CHECK CENTROIDS EVALUATION ================\n');
fprintf('Total Samples Evaluated : %d (Healthy: %d | Sick: %d)\n', ...
    length(Y), size(Features_Healthy, 1), size(Features_Sick, 1));
fprintf('Balanced Accuracy       : %.2f%%\n', acc * 100);
fprintf('F1-score                : %.2f\n', F1);
fprintf('Sensitivity (TPR)       : %.2f\n', sensitivity);
fprintf('Specificity (TNR)       : %.2f\n', specificity);
fprintf('Confusion Matrix        : TP = %d | TN = %d | FP = %d | FN = %d\n', TP, TN, FP, FN);
fprintf('============================================================\n\n');

%% =========================================================================
% PLOT SECTION
% =========================================================================
% Color definitions: Blue for Healthy (+1), Red for Sick (-1)
color_h = [0.1, 0.4, 0.8]; 
color_s = [0.8, 0.2, 0.2]; 

% Boolean masks
is_healthy = (Y == 1);
is_sick    = (Y == -1);
is_correct = (Y == Y_pred);

figure('Name', 'Centroid Validation in HxC Plane');
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

% Plot Target Class Centroids
plot(centroid_healthy(1), centroid_healthy(2), 'kp', 'MarkerSize', 14, ...
    'MarkerFaceColor', 'g', 'LineWidth', 1.5, 'DisplayName', 'Healthy Centroid');
plot(centroid_sick(1), centroid_sick(2), 'kp', 'MarkerSize', 14, ...
    'MarkerFaceColor', 'm', 'LineWidth', 1.5, 'DisplayName', 'Sick Centroid');

xlabel('Entropy (H)');
ylabel('Complexity (C)');
title(sprintf('Centroid Evaluation (Acc: %.1f%%, F1: %.2f, Sens: %.2f, Spec: %.2f)', ...
    acc * 100, F1, sensitivity, specificity));
legend('Location', 'best');
hold off;

end
% Local Helper Function
function Feat = extract_features(folderPath, m, t)
    files = dir(fullfile(folderPath, '*.mat'));
    if isempty(files)
        error('No .mat files found in folder: %s', folderPath);
    end
    Feat = zeros(length(files), 2);
    for i = 1:length(files)
        dataStruct = load(fullfile(folderPath, files(i).name));
        fn = fieldnames(dataStruct);
        [H_val, ~, C_val] = HXC_1_opti(dataStruct.(fn{1}), m, t); 
        Feat(i, :) = [H_val, C_val];
    end
end