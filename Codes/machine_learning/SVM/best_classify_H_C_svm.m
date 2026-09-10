function [BestSVMModel, Features_Healthy, Features_Sick, BestMetrics] = best_classify_H_C_svm(folder_healthy, folder_sick, m, t)

% Extract 2D Features (H and C) for Healthy Patients
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

% Extract 2D Features (H and C) for Sick Patients
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

% Dataset Assembly
X = [Features_Healthy; Features_Sick];            
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)];

best_acc = -1;
BestSVMModel = [];
BestMetrics = struct('Accuracy', 0, 'AUC', 0, 'F1', 0, 'Precision', 0, 'Recall', 0);

disp('Running 10 iterations of Cross-Validation to find the best configuration...');

% Apply cross-validation 10 times and keep the configuration linked with the maximum mean accuracy
for iter = 1:10
    fprintf('\nIteration %d/10...\n', iter);
    
    % Automated Hyperparameter Optimization
    SVMModel = fitcsvm(X, Y, ...
        'Standardize', true, ...
        'ClassNames', [1, -1], ...
        'OptimizeHyperparameters', {'KernelFunction', 'BoxConstraint', 'KernelScale'}, ...
        'HyperparameterOptimizationOptions', struct(...
            'Optimizer', 'bayesopt', ...
            'AcquisitionFunctionName', 'expected-improvement-plus', ...
            'KFold', 10, ...
            'MaxObjectiveEvaluations', 20, ... % Reduced slightly for loop efficiency
            'ShowPlots', false, ...
            'Verbose', 0));
    
    % 10-Fold Cross-Validation Evaluation
    CVMdl = crossval(SVMModel, 'KFold', 10);
    [Y_pred, Y_score] = kfoldPredict(CVMdl);
    
    % Calculate Quality Indicators
    TP = sum((Y == 1) & (Y_pred == 1));
    TN = sum((Y == -1) & (Y_pred == -1));
    FP = sum((Y == -1) & (Y_pred == 1));
    FN = sum((Y == 1) & (Y_pred == -1));
    
    Accuracy = (TP + TN) / (TP + FP + TN + FN);
    
    precision = TP / (TP + FP);
    if isnan(precision), precision = 0; end
    
    recall = TP / (TP + FN);
    if isnan(recall), recall = 0; end
    
    F1 = 2 * (precision * recall) / (precision + recall);
    if isnan(F1), F1 = 0; end
    
    % ClassNames is [1, -1], so column 1 of Y_score corresponds to class 1
    [~, ~, ~, AUC] = perfcurve(Y, Y_score(:,1), 1);
    
    fprintf('  Acc: %.2f%% | AUC: %.2f | F1: %.2f\n', Accuracy*100, AUC, F1);
    
    % Keep the configuration linked with the maximum accuracy
    if Accuracy > best_acc
        best_acc = Accuracy;
        BestSVMModel = SVMModel;
        BestMetrics.Accuracy = Accuracy;
        BestMetrics.AUC = AUC;
        BestMetrics.F1 = F1;
        BestMetrics.Precision = precision;
        BestMetrics.Recall = recall;
    end
end

selectedKernel = BestSVMModel.KernelParameters.Function;
bestC = BestSVMModel.ModelParameters.BoxConstraint;

fprintf('\n=========================================\n');
fprintf('       BEST SVM CONFIGURATION FOUND      \n');
fprintf('=========================================\n');
fprintf(' Selected Kernel : %s\n', upper(selectedKernel));
fprintf(' BoxConstraint C : %.4f\n', bestC);
if isnumeric(BestSVMModel.KernelParameters.Scale)
    fprintf(' Kernel Scale    : %.4f\n', BestSVMModel.KernelParameters.Scale);
end
fprintf(' Best Accuracy   : %.2f%%\n', BestMetrics.Accuracy * 100);
fprintf(' Best AUC        : %.4f\n', BestMetrics.AUC);
fprintf(' Best F1-Score   : %.4f\n', BestMetrics.F1);
fprintf('=========================================\n\n');

% Adaptive Visualization
figure('Color', [1 1 1]); hold on; box on; grid on;

h_min = min(X(:,1)) - 0.03; h_max = max(X(:,1)) + 0.03;
c_min = min(X(:,2)) - 0.03; c_max = max(X(:,2)) + 0.03;

if strcmpi(selectedKernel, 'linear')
    % Linear Rendering
    w_std = BestSVMModel.Beta;
    b_std = BestSVMModel.Bias;
    mu    = BestSVMModel.Mu;
    sigma = BestSVMModel.Sigma;
    
    w_raw = w_std ./ sigma';
    b_raw = b_std - sum((w_std .* mu') ./ sigma');
    
    h_line = linspace(h_min, h_max, 100);
    c_hyperplane   = -(w_raw(1)*h_line + b_raw) / w_raw(2);
    c_margin_plus  = (1 - (w_raw(1)*h_line + b_raw)) / w_raw(2);
    c_margin_minus = (-1 - (w_raw(1)*h_line + b_raw)) / w_raw(2);
    
    plot(h_line, c_hyperplane, 'k-', 'LineWidth', 2, 'DisplayName', 'Decision Boundary');
    plot(h_line, c_margin_plus, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Margin (+1)');
    plot(h_line, c_margin_minus, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Margin (-1)');
else
    % Non-Linear Rendering
    [H_grid, C_grid] = meshgrid(linspace(h_min, h_max, 200), linspace(c_min, c_max, 200));
    [~, scores] = predict(BestSVMModel, [H_grid(:), C_grid(:)]);
    Score_grid = reshape(scores(:,1), size(H_grid)); 
    
    contourf(H_grid, C_grid, Score_grid, [0 0], 'LineColor', 'none');
    colormap([1 0.88 0.88; 0.88 0.88 1]);
    
    contour(H_grid, C_grid, Score_grid, [0 0], 'k-', 'LineWidth', 2, 'DisplayName', 'Decision Boundary');
    contour(H_grid, C_grid, Score_grid, [1 1], 'r--', 'LineWidth', 1.5, 'DisplayName', 'Margin (+1)');
    contour(H_grid, C_grid, Score_grid, [-1 -1], 'b--', 'LineWidth', 1.5, 'DisplayName', 'Margin (-1)');
end

% Plot Feature Point Distributions
plot(Features_Healthy(:,1), Features_Healthy(:,2), 'ro', 'MarkerFaceColor', 'r', ...
    'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', 'Healthy (+1)');
plot(Features_Sick(:,1), Features_Sick(:,2), 'bs', 'MarkerFaceColor', 'b', ...
    'LineWidth', 1.5, 'MarkerSize', 8, 'DisplayName', 'Sick (-1)');

% Highlight Support Vectors
sv = BestSVMModel.SupportVectors;
plot(sv(:,1), sv(:,2), 'ko', 'MarkerSize', 13, ...
    'LineWidth', 2, 'DisplayName', 'Support Vectors');

% Formatting
xlabel('Normalized Permutation Entropy (H)', 'FontSize', 12);
ylabel('MPR Complexity (C)', 'FontSize', 12);
title(sprintf('Auto-Optimized SVM (%s Kernel) - Acc: %.1f%%, AUC: %.2f, F1: %.2f', ...
    upper(selectedKernel), BestMetrics.Accuracy * 100, BestMetrics.AUC, BestMetrics.F1), 'FontSize', 12);
legend('Location', 'best');
xlim([h_min h_max]);
ylim([c_min c_max]);
hold off;
end