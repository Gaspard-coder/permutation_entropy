function plot_WHxC_outliers(folderPath, outputFile, m, t)
% =========================================================================
% PLOT_WHXC_OUTLIERS Computes WHxC features (H and C) for all .mat files
% in folderPath, plots the HxC feature plane with theoretical boundaries
% (C_min and C_max) and numbered points, and writes a mapping CSV file.
%
% Usage:
%   plot_WHxC_outliers('path/to/mat_files', 'mapping.csv', 3, 1)
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

% --- Write Mapping File ---
fid = fopen(outputFile, 'w');
fprintf(fid, 'ID,Filename,wpe_norm,Comp_JS,Folder\n');
for i = 1:numFiles
    fprintf(fid, '%d,%s,%.6f,%.6f,%s\n', fileMapping{i,1}, fileMapping{i,2}, H_vals(i), C_vals(i), folderName);
end
fclose(fid);
fprintf('Mapping saved to: %s\n', outputFile);

% --- Compute Theoretical Boundaries ---
[H_min, C_min, H_max, C_max] = compute_HxC_bounds(m);

% --- Plot WHxC Feature Plane ---
figure('Name', sprintf('WHxC Feature Plane - %s (m=%d, tau=%d)', folderName, m, t), 'Color', 'w');
hold on; grid on; box on;

% Plot theoretical boundaries
plot(H_min, C_min, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Minimum Complexity (C_{min})');
plot(H_max, C_max, 'k-',  'LineWidth', 1.5, 'DisplayName', 'Maximum Complexity (C_{max})');

% Plot data points with specific legend describing the dataset folder
scatter(H_vals, C_vals, 60, 'filled', ...
    'MarkerFaceColor', [0.2 0.4 0.8], ...
    'MarkerEdgeColor', [0.1 0.2 0.5], ...
    'DisplayName', sprintf('Files in "%s" (N = %d)', folderName, numFiles));

% Formatting with precise folder path metadata in title & subtitle
xlabel('Normalized Weighted Permutation Entropy (H)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('MPR Complexity (C)', 'FontSize', 12, 'FontWeight', 'bold');

title(sprintf('Weighted H \\times C Feature Plane: Folder "%s"', folderName), ...
    'FontSize', 13, 'FontWeight', 'bold');
subtitle(sprintf('Parameters: Embedding Dimension m = %d, Time Delay \\tau = %d | Total Files: %d', m, t, numFiles), ...
    'FontSize', 10, 'FontAngle', 'italic');

legend('Location', 'northeast', 'FontSize', 10);
xlim([0 1]);
ylim([0 max(C_max) * 1.1]);

% Add numbered labels next to each file's data point
dx = 0.004;
dy = 0.004;
for i = 1:numFiles
    if ~isnan(H_vals(i)) && ~isnan(C_vals(i))
        text(H_vals(i) + dx, C_vals(i) + dy, num2str(i), ...
            'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
    end
end

hold off;
end

% =========================================================================
% Theoretical Boundaries Computation (C_min and C_max)
% =========================================================================
function [H_min, C_min, H_max, C_max] = compute_HxC_bounds(m)
N = factorial(m);

c1 = (0.5 + ((1 - 0.5) / N)) * log(0.5 + ((1 - 0.5) / N));
c2 = ((1 - 0.5) / N) * log((1 - 0.5) / N) * (N - 1);
c3 = 0.5 * log(N);
Q_0 = -1 / (c1 + c2 + c3);

% Minimum Complexity Curve
numPts = 500;
a_vec = linspace(0, 1, numPts);
H_min = zeros(1, numPts);
C_min = zeros(1, numPts);
for idx = 1:numPts
    a = a_vec(idx);
    p = [(1 - a*(N-1)/N), repmat(a/N, 1, N-1)];
    [H_min(idx), C_min(idx)] = calc_point_HC(p, N, Q_0);
end

% Maximum Complexity Curve
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

% =========================================================================
% Signal Extraction Helper Function
% =========================================================================
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