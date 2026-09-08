function [mean_lambda, std_lambda, lambda_vals] = sub_mean_lyapunov_exponent(data_folder, sample_frequency, approach)
% =========================================================================
% MEAN_LYAPUNOV_EXPONENT 
% Computes average Lyapunov exponent and standard deviation for all
% .mat time series files stored in a directory, applying mean-subtraction
% normalization (Individual vs. Group mean).
%
% Inputs:
%   data_folder      : Path to directory containing .mat time series files.
%   sample_frequency : Sampling frequency of the signal.
%   approach         : 'individual' (default) - Subtracts individual signal mean.
%                      'group'      - Subtracts overall group mean across files.
%                 
% Outputs:
%   mean_lambda : Mean Lyapunov exponent across valid .mat files.
%   std_lambda  : Standard deviation of Lyapunov exponent across files.
%   lambda_vals : Vector containing computed exponent for each file.
%
% Example usage:
%   Approach 1: Individual Mean Subtraction
%   [mu1, sigma1] = mean_lyapunov_exponent('./data_folder', 1000, 'individual');
%
%   Approach 2: Group Mean Subtraction
%   [mu2, sigma2] = mean_lyapunov_exponent('./data_folder', 1000, 'group');
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

    % Pre-load signals to support group-level calculations
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

    lambda_vals = zeros(num_valid, 1);
    valid_count = 0;

    % Temporary directory to pass demeaned signals to lyapunov_exponent
    temp_dir = fullfile(data_folder, 'temp_demeaned');
    if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
    end
    cleanupObj = onCleanup(@() remove_temp_folder(temp_dir));

    % Loop through files and calculate exponents
    for k = 1:num_valid
        filename = valid_files(k).name;
        signal = signals{k};

        % Calculate signal anomaly based on approach
        if strcmp(approach, 'individual')
            proc_signal = signal - mean(signal);
        else
            proc_signal = signal - group_mean;
        end

        % Save temporary MAT file for function compatibility
        temp_file_path = fullfile(temp_dir, ['temp_' filename]);
        data_to_save = proc_signal; 
        save(temp_file_path, 'data_to_save');

        try
            lambda = lyapunov_exponent(temp_file_path, sample_frequency);
            valid_count = valid_count + 1;
            lambda_vals(valid_count) = lambda;
            fprintf('  [%d/%d] %s -> Exponent: %.6f\n', k, num_valid, filename, lambda);
        catch ME
            warning('Failed to compute exponent for %s: %s', filename, ME.message);
        end

        if exist(temp_file_path, 'file')
            delete(temp_file_path);
        end
    end

    if valid_count == 0
        error('No valid .mat files were successfully processed.');
    end

    lambda_vals = lambda_vals(1:valid_count);
    mean_lambda = mean(lambda_vals);
    std_lambda  = std(lambda_vals);

    % Print Summary
    fprintf('\n----------------------------------------\n');
    fprintf('Completed (%d/%d valid files processed | Approach: %s)\n', valid_count, num_valid, approach);
    fprintf('Mean Lyapunov Exponent : %.6f\n', mean_lambda);
    fprintf('Standard Deviation     : %.6f\n', std_lambda);
    fprintf('----------------------------------------\n');
end

function remove_temp_folder(folder_path)
    if exist(folder_path, 'dir')
        rmdir(folder_path, 's');
    end
end
