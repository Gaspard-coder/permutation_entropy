function [mi_array, mi_mean] = internal_PMI_sweep(data_folder, m, t, var1, var2)
% =========================================================================
% INTERNAL_PMI_SWEEP Computes Permutation Mutual Information between two variables
% of a .mat file for all .mat files in a specified folder, calculates their 
% global mean, and visualizes the results.
%
% Inputs:
%   data_folder - Path to directory containing .mat files (string)
%   m           - Embedding dimension
%   t           - Time delay
%   var1        - (Optional) Variable 1 name inside .mat files
%   var2        - (Optional) Variable 2 name inside .mat files
%
% Outputs:
%   mi_array    - Vector (N x 1) of PMI values between var1 and var2 per file
%   mi_mean     - Mean PMI across all files
% =========================================================================

% Get a list of all .mat files
file_pattern = fullfile(data_folder, '*.mat');
file_list = dir(file_pattern);
num_files = length(file_list);

if num_files == 0
    error('No .mat files found in the specified directory: %s', data_folder);
end

mi_array = zeros(num_files, 1);
file_names = cell(num_files, 1);

for k = 1:num_files
    file_names{k} = file_list(k).name;
    full_path = fullfile(data_folder, file_names{k});
    
    % Compute PMI between var1 and var2 inside the current .mat file
    [mi, ~, ~, ~] = perm_mutual_info(full_path, full_path, m, t, var1, var2);
    mi_array(k) = mi;
end

mi_mean = mean(mi_array); % Calculate global mean

% =========================================================================
% Plotting Section
% =========================================================================
figure('Name', 'internal PMI Sweep Results', 'NumberTitle', 'off', 'WindowStyle', 'normal');

% Plot values as a bar chart
bar(mi_array, 'FaceColor', [0.2, 0.4, 0.8]);
hold on;

% Add horizontal reference line for global mean
yline(mi_mean, 'r--', sprintf('Mean PMI = %.4f', mi_mean), ...
    'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');

% Configure X-axis with file names rotated to prevent overlapping text
xticks(1:num_files);
xticklabels(file_names);
xtickangle(45);

% Axis labels and grid formatting
xlabel('File Name', 'FontWeight', 'bold');
ylabel('Permutation Mutual Information (bits)', 'FontWeight', 'bold');

% Set title using folder name (Interpreter 'none' prevents underscore issues)
[~, folder_name] = fileparts(data_folder);
if isempty(folder_name)
    folder_name = data_folder; 
end
title(sprintf(' internal PMI Sweep — Folder: %s', folder_name), 'Interpreter', 'none');

grid on;
box on;
hold off;
end