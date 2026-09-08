function [mean_FD, std_FD, FD_vals] = sub_mean_fractal_dimension(data_folder, k_max, approach)
% =========================================================================
% MEAN_FRACTAL_DIMENSION 
% Computes average Higuchi Fractal Dimension (FD) and standard deviation 
% for all .mat time series files stored in a directory, applying mean-subtraction
% normalization (Individual vs. Group mean).
%
% Inputs:
%   data_folder : Path to directory containing .mat time series files.
%   k_max       : Maximum interval time parameter for Higuchi FD.
%   approach    : 'individual' (default) - Subtracts individual signal mean.
%                 'group'      - Subtracts overall group mean across files.
%                 
% Outputs:
%   mean_FD     : Mean fractal dimension across valid .mat files.
%   std_FD      : Standard deviation of fractal dimension.
%   FD_vals     : Vector containing computed fractal dimension for each file.
%
% Example usage:
%   Approach 1: Individual Mean Subtraction
%   [mu1, sigma1] = mean_fractal_dimension('./data_folder', 10, 'individual');
%
%   Approach 2: Group Mean Subtraction
%   [mu2, sigma2] = mean_fractal_dimension('./data_folder', 10, 'group');
% =========================================================================

    if nargin < 3 || isempty(approach)
        approach = 'individual';
    end
    approach = validatestring(approach, {'individual', 'group'});

    % Validate folder path
    if ~isfolder(data_folder)
        error('Specified directory does not exist: %s', data_folder);
    end

    % Search for all .mat files in the directory
    file_pattern = fullfile(data_folder, '*.mat');
    file_list = dir(file_pattern);
    num_files = length(file_list);

    if num_files == 0
        error('No .mat files found in directory: %s', data_folder);
    end

    % Pre-load signals to compute group statistics if needed
    signals = cell(num_files, 1);
    valid_indices = false(num_files, 1);

    for k = 1:num_files
        file_path = fullfile(data_folder, file_list(k).name);
        try
            loaded_data = load(file_path);
            data_cells = struct2cell(loaded_data);
            if ~isempty(data_cells)
                signals{k} = data_cells{1}(:);
                valid_indices(k) = true;
            end
        catch
            % Skip unreadable files
        end
    end

    signals = signals(valid_indices);
    valid_files = file_list(valid_indices);
    num_valid = length(signals);

    if num_valid == 0
        error('No valid .mat files were successfully loaded.');
    end

    % Determine group mean if requested
    if strcmp(approach, 'group')
        all_data = vertcat(signals{:});
        group_mean = mean(all_data);
        fprintf('\nProcessing %d files using Group Mean Subtraction (Group Mean = %.6f)...\n', num_valid, group_mean);
    else
        fprintf('\nProcessing %d files using Individual Signal Mean Subtraction...\n', num_valid);
    end

    FD_vals = zeros(num_valid, 1);
    valid_count = 0;

    % Loop through files and compute Higuchi FD on demeaned signals
    for k = 1:num_valid
        filename = valid_files(k).name;
        signal = signals{k};

        % Calculate signal anomaly based on approach
        if strcmp(approach, 'individual')
            proc_signal = signal - mean(signal);
        else
            proc_signal = signal - group_mean;
        end

        try
            FD = Higuchi_FD(k_max, proc_signal);
            valid_count = valid_count + 1;
            FD_vals(valid_count) = FD;
            fprintf('  [%d/%d] %s -> Fractal Dimension: %.6f\n', k, num_valid, filename, FD);
        catch ME
            warning('Failed to compute fractal dimension for %s: %s', filename, ME.message);
        end
    end

    if valid_count == 0
        error('No valid .mat files were successfully processed.');
    end

    FD_vals = FD_vals(1:valid_count);
    mean_FD = mean(FD_vals);
    std_FD  = std(FD_vals);

    % Print Summary
    fprintf('\n----------------------------------------\n');
    fprintf('Completed (%d/%d valid files processed | Approach: %s)\n', valid_count, num_valid, approach);
    fprintf('Mean Fractal Dimension : %.6f\n', mean_FD);
    fprintf('Standard Deviation     : %.6f\n', std_FD);
    fprintf('----------------------------------------\n');
end
