function [resultsTable, bestConfig] = HxC_sweep_kmean(folder_healthy, folder_sick, m, t, k)
% =========================================================================
% Performs a full combinatorial grid search over all k-means parameters
% in the HxC feature space:
%   - Distance   : 'sqeuclidean', 'cityblock', 'cosine', 'correlation' (4)
%   - MaxIter    : 1 to 3                                           (3)
%   - Replicates : 1 to 5                                           (5)
%   - Start      : 'plus', 'cluster', 'sample', 'uniform'           (4)
% Total runs = 4 x 3 x 5 x 4 = 240 combinations.
%
% Output:
%   - resultsTable : Complete table of all 240 evaluation runs
%   - bestConfig   : Table containing top configurations for each metric
% =========================================================================

% Extract features & label dataset
fprintf('Extracting features...\n');
Features_Healthy = extract_features(folder_healthy, m, t);
Features_Sick    = extract_features(folder_sick, m, t);
X = [Features_Healthy; Features_Sick];
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% Define Parameter Grid
distances  = {'sqeuclidean', 'cityblock', 'cosine', 'correlation'};
max_iters  = 1:3;
replicates = 1:5;
starts     = {'plus', 'cluster', 'sample', 'uniform'};

% Generate Cartesian product of all parameters
[d_grid, i_grid, r_grid, s_grid] = ndgrid(1:length(distances), ...
    1:length(max_iters), ...
    1:length(replicates), ...
    1:length(starts));

num_combos = numel(d_grid);
fprintf('Starting full grid search (%d total configurations)...\n', num_combos);

% Preallocate output vectors
dist_col  = cell(num_combos, 1);
iter_col  = zeros(num_combos, 1);
rep_col   = zeros(num_combos, 1);
start_col = cell(num_combos, 1);
scores    = zeros(num_combos, 4); % [Accuracy, F1, Sensitivity, Specificity]

% Suppress convergence warnings for constrained sweeps (e.g., MaxIter=1)
warning('off', 'stats:kmeans:FailedToConverge');
warning('off', 'stats:kmeans:MissingData');

% Run Full Grid Search
for idx = 1:num_combos
    d    = distances{d_grid(idx)};
    iter = max_iters(i_grid(idx));
    rep  = replicates(r_grid(idx));
    st   = starts{s_grid(idx)};

    dist_col{idx}  = d;
    iter_col(idx)  = iter;
    rep_col(idx)   = rep;
    start_col{idx} = st;

    scores(idx, :) = evaluate_kmeans(X, Y, k, d, iter, rep, st);
end

% Restore warnings
warning('on', 'stats:kmeans:FailedToConverge');
warning('on', 'stats:kmeans:MissingData');

% Format Main Output Table
resultsTable = table(dist_col, iter_col, rep_col, start_col, ...
    scores(:,1), scores(:,2), scores(:,3), scores(:,4), ...
    'VariableNames', {'Distance', 'MaxIter', 'Replicates', 'Start', ...
    'Accuracy', 'F1_Score', 'Sensitivity', 'Specificity'});

% Extract Best Configurations for Each Metric
[~, idx_acc]  = max(resultsTable.Accuracy, [], 'omitnan');
[~, idx_f1]   = max(resultsTable.F1_Score, [], 'omitnan');
[~, idx_sens] = max(resultsTable.Sensitivity, [], 'omitnan');
[~, idx_spec] = max(resultsTable.Specificity, [], 'omitnan');

Metric = {'Best Accuracy'; 'Best F1-Score'; 'Best Sensitivity'; 'Best Specificity'};
best_indices = [idx_acc; idx_f1; idx_sens; idx_spec];

% Build Summary Table
bestConfig = [table(Metric), resultsTable(best_indices, :)];

% Display console report
fprintf('\n================ TOP CONFIGURATIONS BY METRIC ================\n');
disp(bestConfig);

% Visualization: Performance Impact Dashboard across metrics
% Distance
figure('Name', 'Grid Search Metric Distribution', 'Position', [100, 100, 1100, 700]);

subplot(2, 2, 1);
boxplot(resultsTable.Accuracy, resultsTable.Distance);
title('Balanced Accuracy by Distance'); ylabel('Score'); grid on;

subplot(2, 2, 2);
boxplot(resultsTable.F1_Score, resultsTable.Distance);
title('F1-Score by Distance'); ylabel('Score'); grid on;

subplot(2, 2, 3);
boxplot(resultsTable.Sensitivity, resultsTable.Distance);
title('Sensitivity by Distance'); ylabel('Score'); grid on;

subplot(2, 2, 4);
boxplot(resultsTable.Specificity, resultsTable.Distance);
title('Specificity by Distance'); ylabel('Score'); grid on;

% MaxIter
figure('Name', 'Grid Search Metric Distribution', 'Position', [100, 100, 1100, 700]);

subplot(2, 2, 1);
boxplot(resultsTable.Accuracy, resultsTable.MaxIter);
title('Balanced Accuracy by MaxIter'); ylabel('Score'); grid on;

subplot(2, 2, 2);
boxplot(resultsTable.F1_Score, resultsTable.MaxIter);
title('F1-Score by MaxIter'); ylabel('Score'); grid on;

subplot(2, 2, 3);
boxplot(resultsTable.Sensitivity, resultsTable.MaxIter);
title('Sensitivity by MaxIter'); ylabel('Score'); grid on;

subplot(2, 2, 4);
boxplot(resultsTable.Specificity, resultsTable.MaxIter);
title('Specificity by MaxIter'); ylabel('Score'); grid on;

%Replicates
figure('Name', 'Grid Search Metric Distribution', 'Position', [100, 100, 1100, 700]);

subplot(2, 2, 1);
boxplot(resultsTable.Accuracy, resultsTable.Replicates);
title('Balanced Accuracy by Replicates'); ylabel('Score'); grid on;

subplot(2, 2, 2);
boxplot(resultsTable.F1_Score, resultsTable.Replicates);
title('F1-Score by Replicates'); ylabel('Score'); grid on;

subplot(2, 2, 3);
boxplot(resultsTable.Sensitivity, resultsTable.Replicates);
title('Sensitivity by Replicates'); ylabel('Score'); grid on;

subplot(2, 2, 4);
boxplot(resultsTable.Specificity, resultsTable.Replicates);
title('Specificity by Replicates'); ylabel('Score'); grid on;

% Start
figure('Name', 'Grid Search Metric Distribution', 'Position', [100, 100, 1100, 700]);

subplot(2, 2, 1);
boxplot(resultsTable.Accuracy, resultsTable.Start);
title('Balanced Accuracy by Start'); ylabel('Score'); grid on;

subplot(2, 2, 2);
boxplot(resultsTable.F1_Score, resultsTable.Start);
title('F1-Score by Start'); ylabel('Score'); grid on;

subplot(2, 2, 3);
boxplot(resultsTable.Sensitivity, resultsTable.Start);
title('Sensitivity by Start'); ylabel('Score'); grid on;

subplot(2, 2, 4);
boxplot(resultsTable.Specificity, resultsTable.Start);
title('Specificity by Start'); ylabel('Score'); grid on;

end

% =========================================================================
% Local Helper Function: Single K-Means Evaluator
% =========================================================================
function scores = evaluate_kmeans(X, Y, k, dist, max_iter, reps, start_method)
options = statset('MaxIter', max_iter);
try
    [idx, ~] = kmeans(X, k, 'Distance', dist, 'Replicates', reps, ...
        'Start', start_method, 'Options', options);

    % Align clusters to ground truth: Cluster 1 = Healthy (+1)
    if mean(Y(idx == 1)) < mean(Y(idx == 2))
        idx = 3 - idx;
    end
    Y_pred = (idx == 1) * 2 - 1;

    % Performance Metrics
    TP = sum((Y == 1)  & (Y_pred == 1));
    TN = sum((Y == -1) & (Y_pred == -1));
    FP = sum((Y == -1) & (Y_pred == 1));
    FN = sum((Y == 1)  & (Y_pred == -1));

    sensitivity = TP / max(TP + FN, eps);
    specificity = TN / max(TN + FP, eps);
    acc         = 0.5 * (sensitivity + specificity);
    F1          = 2 * TP / max(2*TP + FP + FN, eps);

    scores = [acc, F1, sensitivity, specificity];
catch
    % Handles non-convergence or empty cluster errors gracefully
    scores = [NaN, NaN, NaN, NaN];
end
end

% =========================================================================
% Local Helper Function: Feature Extractor
% =========================================================================
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