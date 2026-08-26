function [cpe_array, cpe_mean, cpe_std] = internal_CPE_sweep(data_folder, m, t, var1, var2)
% =========================================================================
% CPE_sweep Computes Conditional Permutation Entropy H(Y|X)
% from a signal X to a signal Y stored in .mat files.
%
% Formula: H(Y|X) = H(X, Y) - H(X)

% Inputs:
%   data_folder - Path to directory containing .mat files (string)
%   m           - Embedding dimension
%   t           - Time delay
%   var1        - (Optional) Variable 1 name inside .mat files
%   var2        - (Optional) Variable 2 name inside .mat files
%
% Outputs:
%   cpe_array    - Vector (N x 1) of cpe values between var1 and var2 per file
%   cpe_mean     - Mean cpe across all files
%   cpe_std      - cpe standard deviation
% =========================================================================

% Get a list of all .mat files
file_pattern = fullfile(data_folder, '*.mat');
file_list = dir(file_pattern);
num_files = length(file_list);

if num_files == 0
    error('No .mat files found in the specified directory: %s', data_folder);
end

cpe_array = zeros(num_files, 1);
file_names = cell(num_files, 1);

for k = 1:num_files
    file_names{k} = file_list(k).name;
    full_path = fullfile(data_folder, file_names{k});
    
    % Compute CPE between var1 and var2 inside the current .mat file
    [cpe] = CPE(full_path, full_path, m, t, var1, var2);
    cpe_array(k) = cpe;
end

cpe_mean = mean(cpe_array); % Calculate global mean
cpe_std = std(cpe_array);

% =========================================================================
% Plotting Section
% =========================================================================
figure('Name', 'internal CPE Sweep Results', 'NumberTitle', 'off', 'WindowStyle', 'normal');

% Shaded +/- 1 Std Dev Interval Area
    x_fill = [0.5, num_files + 0.5, num_files + 0.5, 0.5];
    y_fill = [cpe_mean - cpe_std, cpe_mean - cpe_std, cpe_mean + cpe_std, cpe_mean + cpe_std];
    fill(x_fill, y_fill, [0.85, 0.4, 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    hold on;

    % Plot values as a bar chart
    bar(cpe_array, 'FaceColor', [0.2, 0.4, 0.8]);

    % Add horizontal reference line for global mean
    yline(cpe_mean, 'r--', sprintf('Mean = %.4f (Std = %.4f)', cpe_mean, cpe_std), ...
        'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

% Configure X-axis with file names rotated to prevent overlapping text
xticks(1:num_files);
xticklabels(file_names);
xtickangle(45);

% Axis labels and grid formatting
xlabel('File Name', 'FontWeight', 'bold');
ylabel('Conditional Permutation Entropy (bits)', 'FontWeight', 'bold');

% Set title using folder name (Interpreter 'none' prevents underscore issues)
[~, folder_name] = fileparts(data_folder);
if isempty(folder_name)
    folder_name = data_folder; 
end
title(sprintf(' internal CPE Sweep — Folder: %s (m = %d, t = %d)', folder_name,m,t), 'Interpreter', 'none');

grid on;
box on;
hold off;
end