function [results1, results2] = mean_FD_sweep(data_folder1, data_folder2, k_range)
% MEAN_FD_SWEEP Computes and plots the evolution of the mean Higuchi 
% Fractal Dimension across a range of k_max values for two folders with 
% standard deviation error bars.
%
% Inputs:
%   data_folder1 : Path to the first directory containing .mat files.
%   data_folder2 : Path to the second directory containing .mat files.
%   k_range      : Vector of k_max values to sweep over (e.g., 2:2:20).
%
% Outputs (Optional):
%   results1     : Struct containing 'means' and 'stds' for folder 1.
%   results2     : Struct containing 'means' and 'stds' for folder 2.
%
% Example usage:
%   mean_FD_sweep('./folder_control', './folder_treatment', 2:2:20);

    % Preallocate memory for speed
    num_k = length(k_range);
    mean1 = zeros(num_k, 1);
    std1  = zeros(num_k, 1);
    mean2 = zeros(num_k, 1);
    std2  = zeros(num_k, 1);

    fprintf('\n===================================================\n');
    fprintf('Starting Fractal Dimension Sweep across k_range...\n');
    fprintf('===================================================\n');

    % Iterate through each k_max value in k_range
    for i = 1:num_k
        k_val = k_range(i);
        fprintf('\n>>> Processing k_max = %d (%d/%d) <<<\n', k_val, i, num_k);
        
        % Compute for Folder 1
        [mean1(i), std1(i), ~] = mean_fractal_dimension(data_folder1, k_val);
        
        % Compute for Folder 2
        [mean2(i), std2(i), ~] = mean_fractal_dimension(data_folder2, k_val);
    end

    % Extract folder names for clean legend display
    [~, name1] = fileparts(data_folder1);
    if isempty(name1), name1 = data_folder1; end
    [~, name2] = fileparts(data_folder2);
    if isempty(name2), name2 = data_folder2; end

    % Generate Plot
    figure('Color', 'w', 'Name', 'Fractal Dimension Sweep');
    hold on;

    % Plot Folder 1
    errorbar(k_range, mean1, std1, '-o', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'CapSize', 6, ...
        'DisplayName', sprintf('Folder: %s', name1));

    % Plot Folder 2
    errorbar(k_range, mean2, std2, '-s', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'CapSize', 6, ...
        'DisplayName', sprintf('Folder: %s', name2));

    hold off;

    % Axes formatting and labels
    grid on;
    box on;
    xlabel('k_{max} Parameter', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Mean Fractal Dimension (FD)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Evolution of Mean Fractal Dimension vs. k_{max}', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'Interpreter', 'none');

    % Package output structs
    results1.k_range = k_range;
    results1.means   = mean1;
    results1.stds    = std1;

    results2.k_range = k_range;
    results2.means   = mean2;
    results2.stds    = std2;
end
