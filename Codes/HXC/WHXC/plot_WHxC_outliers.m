function plot_WHxC_outliers(folderPath, outputFile, m, t, k)
% =========================================================================
% PLOT_WHXC_OUTLIERS Computes WHxC features (H and C) for all .mat files
% in folderPath, computes k-means cluster centroids, plots the WHxC feature
% plane with theoretical boundaries (C_min and C_max) & centroid coordinates,
% plots point-wise centroid distance distributions, and writes a detailed CSV mapping.
%
% Usage:
%   plot_WHxC_outliers('path/to/mat_files', 'mapping.csv', 3, 1, 2)
% =========================================================================

if nargin < 1 || isempty(folderPath)
    folderPath = '.';
end
if nargin < 2 || isempty(outputFile)
    outputFile = 'subject_number_mapping.csv';
end
if nargin < 3 || isempty(m)
    m = 3; % Default embedding dimension
end
if nargin < 4 || isempty(t)
    t = 1; % Default time delay
end
if nargin < 5 || isempty(k)
    k = 2; % Default number of clusters
end

% Extract folder name for precise titling
cleanFolderPath = char(folderPath);
if length(cleanFolderPath) > 1 && (cleanFolderPath(end) == '/' || cleanFolderPath(end) == '\')
    cleanFolderPath = cleanFolderPath(1:end-1);
end
[~, folderName, ext] = fileparts(cleanFolderPath);
if isempty(folderName)
    folderName = 'Current Working Directory';
else
    folderName = [folderName, ext];
end

% Get list of all .mat files in directory
matFiles = dir(fullfile(folderPath, '*.mat'));
numFiles = length(matFiles);
if numFiles == 0
    error('No .mat files found in the specified directory: %s', folderPath);
end

% Preallocate vectors and mapping cell array
H_vals = zeros(numFiles, 1);
C_vals = zeros(numFiles, 1);
fileMapping = cell(numFiles, 2);

fprintf('Processing %d files from [%s] using WHXC (m=%d, tau=%d)...\n', numFiles, folderName, m, t);

for i = 1:numFiles
    fileName = matFiles(i).name;
    fullFilePath = fullfile(folderPath, fileName);

    % Load .mat file
    data = load(fullFilePath);

    % Extract data vector
    signal = extract_signal_vector(data);

    % Compute WHXC features
    [~, ~, wpe_norm, ~, Comp_JS] = WHXC(signal, m, t);

    H_vals(i) = wpe_norm;
    C_vals(i) = Comp_JS;
    fileMapping{i, 1} = i;
    fileMapping{i, 2} = fileName;
end

X = [H_vals, C_vals];

% =========================================================================
% K-Means Clustering & Centroid Computation
% =========================================================================
k_actual = min(k, numFiles); % Adjust if total files are less than k
[idx, C_centroids, ~, D_sq] = kmeans(X, k_actual, 'Distance', 'sqeuclidean', ...
    'Replicates', 1, 'MaxIter', 100, 'Start', 'plus');

% Convert squared Euclidean distances to standard Euclidean distances
D_euc = sqrt(D_sq);

% Distance from each point to its assigned centroid
dist_assigned = zeros(numFiles, 1);
for i = 1:numFiles
    dist_assigned(i) = D_euc(i, idx(i));
end

% =========================================================================
% Write CSV Output File (Safe Directory Creation & Writing)
% =========================================================================
outDir = fileparts(outputFile);
if ~isempty(outDir) && ~exist(outDir, 'dir')
    mkdir(outDir);
    fprintf('Created missing target directory: %s\n', outDir);
end

fid = fopen(outputFile, 'w');
if fid == -1
    error('Unable to create or write to file: %s. Check folder permissions.', outputFile);
end

% CSV Header
fprintf(fid, 'ID,Filename,wpe_norm,Comp_JS,Assigned_Cluster,Dist_Assigned_Centroid');
for c = 1:k_actual
    fprintf(fid, ',Dist_Centroid_%d', c);
end
fprintf(fid, ',Folder\n');

% Write per-file data rows
for i = 1:numFiles
    fprintf(fid, '%d,%s,%.6f,%.6f,%d,%.6f', ...
        fileMapping{i,1}, fileMapping{i,2}, H_vals(i), C_vals(i), idx(i), dist_assigned(i));
    for c = 1:k_actual
        fprintf(fid, ',%.6f', D_euc(i, c));
    end
    fprintf(fid, ',%s\n', folderName);
end

% Append Centroid Coordinates Section at the bottom of the CSV
fprintf(fid, '\n# ==========================================\n');
fprintf(fid, '# CLUSTER CENTROIDS COORDINATES (H, C)\n');
fprintf(fid, '# ==========================================\n');
fprintf(fid, '# Cluster_ID,Entropy_H,Complexity_C\n');
for c = 1:k_actual
    fprintf(fid, '# Centroid_%d,%.6f,%.6f\n', c, C_centroids(c, 1), C_centroids(c, 2));
end

fclose(fid);
fprintf('Mapping and Centroid coordinates saved to: %s\n', outputFile);

% Display Centroids in Command Window
fprintf('\n================ CLUSTER CENTROIDS (H, C) ================\n');
for c = 1:k_actual
    fprintf('  Centroid %d : H = %.4f, C = %.4f\n', c, C_centroids(c, 1), C_centroids(c, 2));
end
fprintf('==========================================================\n\n');

% Compute Theoretical Boundaries
[H_min, C_min, H_max, C_max] = compute_HxC_bounds(m);

% =========================================================================
% Figure 1: WHxC Feature Plane with Centroids (Legend Only)
% =========================================================================
figure('Name', sprintf('WHxC Feature Plane - %s (m=%d, tau=%d)', folderName, m, t), 'Color', 'w');
hold on; grid on; box on;

% Plot theoretical boundaries
plot(H_min, C_min, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Minimum Complexity (C_{min})');
plot(H_max, C_max, 'k-',  'LineWidth', 1.5, 'DisplayName', 'Maximum Complexity (C_{max})');

% Color definitions for clusters
colors = lines(k_actual);

% Scatter plot data points grouped by cluster
for c = 1:k_actual
    mask = (idx == c);
    scatter(H_vals(mask), C_vals(mask), 60, colors(c, :), 'filled', ...
        'DisplayName', sprintf('Cluster %d Points (N = %d)', c, sum(mask)));
end

% Plot Cluster Centroids (Coordinates displayed in Legend only)
for c = 1:k_actual
    plot(C_centroids(c, 1), C_centroids(c, 2), 'kp', ...
        'MarkerSize', 14, 'MarkerFaceColor', colors(c, :), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Centroid %d (H=%.4f, C=%.4f)', c, C_centroids(c, 1), C_centroids(c, 2)));
end

% Title & Labels
xlabel('Normalized Weighted Permutation Entropy (H)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('MPR Complexity (C)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Weighted H \\times C Feature Plane: Folder "%s"', folderName), ...
    'FontSize', 13, 'FontWeight', 'bold');
subtitle(sprintf('Parameters: m = %d, \\tau = %d | Total Files: %d | Clusters: k = %d', m, t, numFiles, k_actual), ...
    'FontSize', 10, 'FontAngle', 'italic');
legend('Location', 'northeast', 'FontSize', 9);
xlim([0 1]);
ylim([0 max(C_max) * 1.1]);

% Add numbered labels next to each file point
dx = 0.004;
dy = 0.004;
for i = 1:numFiles
    if ~isnan(H_vals(i)) && ~isnan(C_vals(i))
        text(H_vals(i) + dx, C_vals(i) + dy, num2str(i), ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
    end
end
hold off;

% =========================================================================
% Figure 2: Centroid Distances per Point Index with 1*SD & 2*SD Thresholds
% =========================================================================
figure('Name', sprintf('Centroid Distance per Point - %s', folderName), 'Color', 'w');

mean_dist = mean(dist_assigned);
std_dist  = std(dist_assigned);

if k_actual == 1
    hold on; grid on; box on;
    bar(1:numFiles, dist_assigned, 'FaceColor', colors(1, :), 'EdgeColor', 'k', 'FaceAlpha', 0.85);

    xlabel('Point Number (File / Subject ID)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Euclidean Distance to Centroid', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('Distance to Cluster Centroid per Point: %s', folderName), 'FontSize', 12, 'FontWeight', 'bold');

    yline(mean_dist, 'r--', sprintf('Mean = %.4f', mean_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(mean_dist + std_dist, 'b--', sprintf('+1 SD Threshold = %.4f', mean_dist + std_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(mean_dist + 2*std_dist, 'm:', sprintf('+2 SD Threshold = %.4f', mean_dist + 2*std_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');

    xticks(1:numFiles);
    xlim([0.5, numFiles + 0.5]);
    hold off;
else
    % Subplot 1: Distance to Assigned Centroid for Each Point
    subplot(2, 1, 1);
    hold on; grid on; box on;

    for i = 1:numFiles
        bar(i, dist_assigned(i), 'FaceColor', colors(idx(i), :), 'EdgeColor', 'k', 'FaceAlpha', 0.85);
    end

    xlabel('Point Number (File / Subject ID)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Distance to Assigned Centroid', 'FontSize', 11, 'FontWeight', 'bold');
    title('Distance to Assigned Cluster Centroid for Each Point', 'FontSize', 11, 'FontWeight', 'bold');

    yline(mean_dist, 'r--', sprintf('Mean = %.4f', mean_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(mean_dist + std_dist, 'b--', sprintf('+1 SD Threshold = %.4f', mean_dist + std_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(mean_dist + 2*std_dist, 'm:', sprintf('+2 SD Threshold = %.4f', mean_dist + 2*std_dist), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');

    xticks(1:numFiles);
    xlim([0.5, numFiles + 0.5]);
    hold off;

    % Subplot 2: Distances to All Cluster Centroids Side-by-Side per Point
    subplot(2, 1, 2);
    b = bar(1:numFiles, D_euc, 'grouped');
    grid on; box on;

    for c = 1:k_actual
        b(c).FaceColor = colors(c, :);
        b(c).DisplayName = sprintf('Distance to Centroid %d', c);
    end

    xlabel('Point Number (File / Subject ID)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Euclidean Distance', 'FontSize', 11, 'FontWeight', 'bold');
    title('Distances to Each Cluster Centroid per Point', 'FontSize', 11, 'FontWeight', 'bold');
    legend('Location', 'northeast');
    xticks(1:numFiles);
    xlim([0.5, numFiles + 0.5]);
end

end

% =========================================================================
% LOCAL HELPER FUNCTIONS
% =========================================================================

function [H_min, C_min, H_max, C_max] = compute_HxC_bounds(m)
N = factorial(m);
c1 = (0.5 + ((1 - 0.5) / N)) * log(0.5 + ((1 - 0.5) / N));
c2 = ((1 - 0.5) / N) * log((1 - 0.5) / N) * (N - 1);
c3 = 0.5 * log(N);
Q_0 = -1 / (c1 + c2 + c3);

numPts = 500;
a_vec = linspace(0, 1, numPts);
H_min = zeros(1, numPts);
C_min = zeros(1, numPts);
for idx = 1:numPts
    a = a_vec(idx);
    p = [(1 - a*(N-1)/N), repmat(a/N, 1, N-1)];
    [H_min(idx), C_min(idx)] = calc_point_HC(p, N, Q_0);
end

numPtsSeg = 100;
H_max = [];
C_max = [];
for k = 1:(N - 1)
    a_seg = linspace(0, 1, numPtsSeg);
    for idx = 1:numPtsSeg
        a = a_seg(idx);
        p = zeros(1, N);
        p(1:k) = (1 - a)/k + a/(k+1);
        p(k+1) = a/(k+1);
        [h_val, c_val] = calc_point_HC(p, N, Q_0);
        H_max = [H_max, h_val];
        C_max = [C_max, c_val];
    end
end
end

function [H_norm, Comp_JS] = calc_point_HC(p, N, Q_0)
p_pos = p(p > 0);
H_p = -sum(p_pos .* log(p_pos));
H_norm = H_p / log(N);
u = 1 / N;
p_mix = 0.5 * p + 0.5 * u;
H_mix = -sum(p_mix .* log(p_mix));
H_u = log(N);
JSD = H_mix - 0.5 * H_p - 0.5 * H_u;
Comp_JS = Q_0 * JSD * H_norm;
end

function signal = extract_signal_vector(dataStruct)
fields = fieldnames(dataStruct);
priorityFields = {'cgm', 'glucose', 'data', 'y', 'signal', 'Val'};
for k = 1:length(priorityFields)
    if isfield(dataStruct, priorityFields{k})
        signal = dataStruct.(priorityFields{k});
        return;
    end
end
for k = 1:length(fields)
    val = dataStruct.(fields{k});
    if isnumeric(val) && (isvector(val) || ismatrix(val))
        signal = val;
        return;
    end
end
error('Could not automatically identify a numeric data vector in .mat file.');
end
