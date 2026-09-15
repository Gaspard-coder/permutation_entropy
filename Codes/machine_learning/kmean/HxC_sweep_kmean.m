function [resultsTable, bestConfig] = HxC_sweep_kmean(folder_healthy, folder_sick, m, t, k)
% =========================================================================
% Full combinatorial grid search over all k-means parameters in HxC space.
% Evaluates metric overlaps and displays the top configurations meeting ALL
% 4 best metric groups (or 3/4 fallback) as a formatted output table.
% =========================================================================

% Fix random seed for deterministic reproducibility across runs
rng(42);

% Extract features & label dataset
fprintf('Extracting features...\n');
Features_Healthy = extract_features(folder_healthy, m, t);
Features_Sick    = extract_features(folder_sick, m, t);
X = [Features_Healthy; Features_Sick];
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

% Define Parameter Grid
distances  = {'sqeuclidean', 'cityblock', 'cosine', 'correlation'};
max_iters  = [100, 1000, 5000];
replicates = 1:5;
starts     = {'plus', 'cluster', 'sample', 'uniform'};

[d_grid, i_grid, r_grid, s_grid] = ndgrid(1:length(distances), ...
    1:length(max_iters), 1:length(replicates), 1:length(starts));

num_combos = numel(d_grid);
fprintf('Starting full grid search (%d total configurations)...\n', num_combos);

dist_col  = cell(num_combos, 1);
iter_col  = zeros(num_combos, 1);
rep_col   = zeros(num_combos, 1);
start_col = cell(num_combos, 1);
scores    = zeros(num_combos, 4);

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

warning('on', 'stats:kmeans:FailedToConverge');
warning('on', 'stats:kmeans:MissingData');

% Format Main Output Table
resultsTable = table(dist_col, iter_col, rep_col, start_col, ...
    scores(:,1), scores(:,2), scores(:,3), scores(:,4), ...
    'VariableNames', {'Distance', 'MaxIter', 'Replicates', 'Start', ...
    'Accuracy', 'F1_Score', 'Sensibility', 'Specificity'});

% Identify Maximum Values Per Metric (Handling Ties)
max_acc  = max(resultsTable.Accuracy, [], 'omitnan');
is_acc   = abs(resultsTable.Accuracy - max_acc) < 1e-6;

max_f1   = max(resultsTable.F1_Score, [], 'omitnan');
is_f1    = abs(resultsTable.F1_Score - max_f1) < 1e-6;

max_sens = max(resultsTable.Sensibility, [], 'omitnan');
is_sens  = abs(resultsTable.Sensibility - max_sens) < 1e-6;

max_spec = max(resultsTable.Specificity, [], 'omitnan');
is_spec  = abs(resultsTable.Specificity - max_spec) < 1e-6;

% Count how many best metric groups each configuration satisfies
group_score = is_acc + is_f1 + is_sens + is_spec;

% Filter: Configurations matching ALL 4 best metrics, else fallback to >= 3
selected_idx = find(group_score == 4);
metric_label = 'Best All (4/4)';

if isempty(selected_idx)
    selected_idx = find(group_score >= 3);
    metric_label = 'Best (3/4)';
end

Metric     = repmat({metric_label}, length(selected_idx), 1);
bestConfig = [table(Metric), resultsTable(selected_idx, :)];

% Display Top Configurations Table in Command Window
fprintf('\n================ TOP CONFIGURATIONS BY METRIC ================\n');
disp(bestConfig);

% Grid Parameter Impact Boxplots
params      = {'Distance', 'MaxIter', 'Replicates', 'Start'};
metric_cols = {'Accuracy', 'F1_Score', 'Sensibility', 'Specificity'};
metric_lbls = {'Balanced Accuracy', 'F1-Score', 'Sensibility', 'Specificity'};

for p = 1:length(params)
    param_name = params{p};
    figure('Name', sprintf('Grid Search: Impact of %s', param_name), ...
        'Position', [100 + (p*30), 100 + (p*30), 1000, 650]);
    for m_idx = 1:length(metric_cols)
        subplot(2, 2, m_idx);
        boxplot(resultsTable.(metric_cols{m_idx}), resultsTable.(param_name));
        title(sprintf('%s vs %s', metric_lbls{m_idx}, param_name));
        xlabel(param_name);
        ylabel('Score');
        ylim([0 1.05]);
        grid on;
    end
end
end

% =========================================================================
% Local Helper Function: Single K-Means Evaluator
% =========================================================================
function scores = evaluate_kmeans(X, Y, k, dist, max_iter, reps, start_method)
options = statset('MaxIter', max_iter);
try
    [idx, ~] = kmeans(X, k, 'Distance', dist, 'Replicates', reps, ...
        'Start', start_method, 'Options', options);
    if mean(Y(idx == 1)) < mean(Y(idx == 2))
        idx = 3 - idx;
    end
    Y_pred = (idx == 1) * 2 - 1;
    TP = sum((Y == 1)  & (Y_pred == 1));
    TN = sum((Y == -1) & (Y_pred == -1));
    FP = sum((Y == -1) & (Y_pred == 1));
    FN = sum((Y == 1)  & (Y_pred == -1));
    Sensibility = TP / max(TP + FN, eps);
    specificity = TN / max(TN + FP, eps);
    acc         = 0.5 * (Sensibility + specificity);
    F1          = 2 * TP / max(2*TP + FP + FN, eps);
    scores = [acc, F1, Sensibility, specificity];
catch
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