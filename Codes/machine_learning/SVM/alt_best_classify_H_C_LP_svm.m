function [BestSVMModel, Features_Healthy, Features_Sick, BestMetrics] = best_classify_H_C_LP_svm(folder_healthy, folder_sick, m, t, sample_frequency)
% Batch processes healthy and sick datasets to extract a 3D feature space (H, C, LP),
% tests 10 different SVM configurations using 10-fold Cross-Validation, evaluates 
% quality metrics, and visualizes the optimal decision surface in 3D.

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

    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 
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

    [H_val, ~, C_val] = HXC_1_opti(y, m, t); 
    lp_val = lyapunov_exponent(filePath, sample_frequency); 

    Features_Sick(i, :) = [H_val, C_val, lp_val]; 
end

% Dataset Assembly
X = [Features_Healthy; Features_Sick];             
Y = [ones(size(Features_Healthy, 1), 1); -ones(size(Features_Sick, 1), 1)]; 

best_acc = -1;
BestSVMModel = [];
BestMetrics = struct('Accuracy', 0, 'AUC', 0, 'F1', 0, 'Precision', 0, 'Recall', 0);

disp('Testing 10 predefined SVM configurations using 10-Fold Cross-Validation...');

% Define 10 distinct configurations to test
configs = struct(...
    'Kernel', {'linear', 'linear', 'gaussian', 'gaussian', 'gaussian', 'gaussian', 'gaussian', 'gaussian', 'gaussian', 'gaussian'}, ...
    'C', {0.1, 1, 0.1, 1, 10, 100, 1, 10, 100, 10}, ...
    'Scale', {'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 0.5, 0.5, 0.5, 2.0});

% Loop through each configuration
for iter = 1:10
    kFunc = configs(iter).Kernel;
    boxC = configs(iter).C;
    kScale = configs(iter).Scale;
    
    % Train the SVM model on the full dataset with the current configuration
    if strcmp(kFunc, 'gaussian')
        SVMModel = fitcsvm(X, Y, 'Standardize', true, 'KernelFunction', kFunc, ...
            'BoxConstraint', boxC, 'KernelScale', kScale);
    else
        SVMModel = fitcsvm(X, Y, 'Standardize', true, 'KernelFunction', kFunc, ...
            'BoxConstraint', boxC);
    end
    
    % Apply 10-Fold Cross Validation
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
    
    [~, ~, ~, AUC] = perfcurve(Y, Y_score(:,1), 1); 
    
    % Print details for each tested SVM configuration
    iterKernel = SVMModel.KernelParameters.Function;
    iterC = SVMModel.ModelParameters.BoxConstraint;
    iterScale = SVMModel.KernelParameters.Scale;
    
    fprintf('\n--- TEST SVM CONFIGURATION %d/10 ---\n', iter); 
    fprintf(' Selected Kernel : %s\n', upper(iterKernel)); 
    fprintf(' BoxConstraint C : %.4f\n', iterC); 
    if isnumeric(iterScale) && ~isempty(iterScale)
        fprintf(' Kernel Scale    : %.4f\n', iterScale); 
    else
        fprintf(' Kernel Scale    : N/A\n'); 
    end
    fprintf(' Average Accuracy   : %.2f%%\n', Accuracy * 100); 
    fprintf(' Average AUC        : %.4f\n', AUC); 
    fprintf(' Average F1-Score   : %.4f\n', F1); 
    fprintf('------------------------------------\n');
    
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
if isnumeric(BestSVMModel.KernelParameters.Scale) && ~isempty(BestSVMModel.KernelParameters.Scale)
    fprintf(' Kernel Scale    : %.4f\n', BestSVMModel.KernelParameters.Scale); 
else
    fprintf(' Kernel Scale    : N/A\n'); 
end
fprintf(' Best Accuracy   : %.2f%%\n', BestMetrics.Accuracy * 100); 
fprintf(' Best AUC        : %.4f\n', BestMetrics.AUC); 
fprintf(' Best F1-Score   : %.4f\n', BestMetrics.F1); 
fprintf('=========================================\n\n'); 

% Adaptive 3D Visualization
figure('Color', [1 1 1]); hold on; box on; grid on; 

h_min = min(X(:,1)) - 0.02; h_max = max(X(:,1)) + 0.02; 
c_min = min(X(:,2)) - 0.02; c_max = max(X(:,2)) + 0.02; 
lp_min = min(X(:,3)) - 0.02; lp_max = max(X(:,3)) + 0.02; 

[H_grid, C_grid] = meshgrid(linspace(h_min, h_max, 30), linspace(c_min, c_max, 30)); 

if strcmpi(selectedKernel, 'linear')
    % 3D Linear Hyperplane Rendering
    w_std = BestSVMModel.Beta; 
    b_std = BestSVMModel.Bias; 
    mu    = BestSVMModel.Mu; 
    sigma = BestSVMModel.Sigma; 
    
    w_raw = w_std ./ sigma'; 
    b_raw = b_std - sum((w_std .* mu') ./ sigma'); 
    
    LP_plane = -(w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw) / w_raw(3); 
    LP_margin_plus  = (1 - (w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw)) / w_raw(3); 
    LP_margin_minus = (-1 - (w_raw(1)*H_grid + w_raw(2)*C_grid + b_raw)) / w_raw(3); 
    
    surf(H_grid, C_grid, LP_plane, 'FaceColor', [0.5 0.5 0.5], ...
        'FaceAlpha', 0.4, 'EdgeColor', 'k', 'EdgeAlpha', 0.3, ...
        'DisplayName', 'Decision Boundary Plane'); 
    surf(H_grid, C_grid, LP_margin_plus, 'FaceColor', 'r', ...
        'FaceAlpha', 0.12, 'EdgeColor', 'none', 'DisplayName', 'Margin (+1)'); 
    surf(H_grid, C_grid, LP_margin_minus, 'FaceColor', 'b', ...
        'FaceAlpha', 0.12, 'EdgeColor', 'none', 'DisplayName', 'Margin (-1)'); 
else
    % 3D Non-Linear Slice/Boundary Rendering
    [H_3D, C_3D, LP_3D] = meshgrid(linspace(h_min, h_max, 30), linspace(c_min, c_max, 30), linspace(lp_min, lp_max, 30));
    grid_pts = [H_3D(:), C_3D(:), LP_3D(:)];
    [~, scores] = predict(BestSVMModel, grid_pts);
    Score_grid = reshape(scores(:,1), size(H_3D));
    
    p = patch(isosurface(H_3D, C_3D, LP_3D, Score_grid, 0));
    p.FaceColor = [0.5 0.5 0.5];
    p.EdgeColor = 'none';
    p.FaceAlpha = 0.5;
    camlight; lighting gouraud;
end

% Plot Feature Point Distributions
scatter3(Features_Healthy(:,1), Features_Healthy(:,2), Features_Healthy(:,3), ...
    80, 'r', 'o', 'filled', 'DisplayName', 'Healthy (+1)'); 
scatter3(Features_Sick(:,1), Features_Sick(:,2), Features_Sick(:,3), ...
    80, 'b', 's', 'filled', 'DisplayName', 'Sick (-1)'); 

% Highlight Support Vectors
sv = BestSVMModel.SupportVectors;
if ~isempty(BestSVMModel.Mu)
    sv_raw = (sv .* BestSVMModel.Sigma) + BestSVMModel.Mu;
else
    sv_raw = sv;
end
scatter3(sv_raw(:,1), sv_raw(:,2), sv_raw(:,3), ...
    160, 'k', 'o', 'LineWidth', 2, 'DisplayName', 'Support Vectors'); 

% Formatting
xlabel('Normalized Permutation Entropy (H)', 'FontSize', 11); 
ylabel('MPR Complexity (C)', 'FontSize', 11); 
zlabel('Lyapunov Exponent (LP)', 'FontSize', 11); 
title(sprintf('Auto-Optimized 3D SVM (%s Kernel) - Acc: %.1f%%, AUC: %.2f, F1: %.2f', ...
    upper(selectedKernel), BestMetrics.Accuracy * 100, BestMetrics.AUC, BestMetrics.F1), 'FontSize', 11); 
legend('Location', 'best'); 
view(3); 
rotate3d on; 
xlim([h_min h_max]); 
ylim([c_min c_max]); 
zlim([lp_min lp_max]); 
hold off; 
end
