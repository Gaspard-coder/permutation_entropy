    function [te_array, te_mean, te_std] = internal_TE_sweep(data_folder, m, t, var1, var2)
% =========================================================================
% TE_sweep Computes Transfer Entropy
% from a signal X to a signal Y stored in .mat files.
% Inputs:
%   data_folder - Path to directory containing .mat files (string)
%   m           - Embedding dimension
%   t           - Time delay
%   var1        - (Optional) Variable 1 name inside .mat files
%   var2        - (Optional) Variable 2 name inside .mat files
%
% Outputs:
%   te_array    - Vector (N x 1) of TE values between var1 and var2 per file
%   te_mean     - Mean TE across all files
%   te_std      - TE standard deviation
% =========================================================================

% Get a list of all .mat files
file_pattern = fullfile(data_folder, '*.mat');
file_list = dir(file_pattern);
num_files = length(file_list);

if num_files == 0
    error('No .mat files found in the specified directory: %s', data_folder);
end

te_array = zeros(num_files, 1);
file_names = cell(num_files, 1);

for k = 1:num_files
    file_names{k} = file_list(k).name;
    full_path = fullfile(data_folder, file_names{k});
    
    % Compute TE between var1 and var2 inside the current .mat file
    [te] = perm_transfer_entropy(full_path, full_path, m, t, var1, var2);
    te_array(k) = te;
end

te_mean = mean(te_array); % Calculate global mean
te_std = std(te_array);

% =========================================================================
% Plotting Section
% =========================================================================
figure('Name', 'internal TE Sweep Results', 'NumberTitle', 'off', 'WindowStyle', 'normal');

% Shaded +/- 1 Std Dev Interval Area
    x_fill = [0.5, num_files + 0.5, num_files + 0.5, 0.5];
    y_fill = [te_mean - te_std, te_mean - te_std, te_mean + te_std, te_mean + te_std];
    fill(x_fill, y_fill, [1, 0.4, 1], 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    hold on;

    % Plot values as a bar chart
    bar(te_array, 'FaceColor', [0.2, 0.8, 0.2]);

    % Add horizontal reference line for global mean
    yline(te_mean, 'r--', sprintf('Mean = %.4f (Std = %.4f)', te_mean, te_std), ...
        'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

% Configure X-axis with file names rotated to prevent overlapping text
xticks(1:num_files);
xticklabels(file_names);
xtickangle(45);

% Axis labels and grid formatting
xlabel('File Name', 'FontWeight', 'bold');
ylabel('Permutation Transfer Entropy (bits)', 'FontWeight', 'bold');

% Set title using folder name (Interpreter 'none' prevents underscore issues)
[~, folder_name] = fileparts(data_folder);
if isempty(folder_name)
    folder_name = data_folder; 
end
title(sprintf(' internal TE Sweep — Folder: %s (m = %d, t = %d)', folder_name,m,t), 'Interpreter', 'none');

grid on;
box on;
hold off;
end