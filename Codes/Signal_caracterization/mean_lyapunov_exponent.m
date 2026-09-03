function [mean_lambda, std_lambda, lambda_vals] = mean_lyapunov_exponent(data_folder, sample_frequency)
% =========================================================================
% MEAN_LYAPUNOV_EXPONENT 
% Computes the average Lyapunov exponent and standard deviation for all
% .mat time series files stored in a specified directory.
%
% Inputs:
%   data_folder : String or char array specifying the path to the directory.
%   sample_frequency    : needs to be the same as the sampling frequency of
%   the signal
%                 
% Outputs:
%   mean_lambda : Mean Lyapunov exponent across all valid .mat files.
%   std_lambda  : Standard deviation of the Lyapunov exponent across files.
%   lambda_vals : Vector containing the computed exponent for each file.
%
% Example usage:
%   [mu, sigma] = mean_lyapunov_exponent('./data_folder', 1000);
% =========================================================================

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

    % Preallocate memory
    lambda_temp = zeros(num_files, 1);
    fprintf('\nProcessing %d files in folder: %s...\n', num_files, data_folder);

    valid_count = 0;
    
    % Loop through files and call lyapunov_exponent.m
    for k = 1:num_files
        
        filename = file_list(k).name;
        file_path = fullfile(data_folder, filename);

        % Call external lyapunov_exponent.m function safely
        try
            lambda = lyapunov_exponent(file_path, sample_frequency);
            
            valid_count = valid_count + 1;
            lambda_temp(valid_count) = lambda;
            fprintf('  [%d/%d] %s -> Exponent: %.6f\n', k, num_files, filename, lambda);
        catch ME
            warning('Failed to compute exponent for %s: %s', filename, ME.message);
        end
    end

    if valid_count == 0
        error('No valid .mat files were successfully processed.');
    end

    % Compute statistics on valid outputs
    lambda_vals = lambda_temp(1:valid_count);
    mean_lambda = mean(lambda_vals);
    std_lambda  = std(lambda_vals);

    % Print Summary
    fprintf('\n----------------------------------------\n');
    fprintf('Completed (%d/%d valid files processed)\n', valid_count, num_files);
    fprintf('Mean Lyapunov Exponent : %.6f\n', mean_lambda);
    fprintf('Standard Deviation     : %.6f\n', std_lambda);
    fprintf('----------------------------------------\n');
end