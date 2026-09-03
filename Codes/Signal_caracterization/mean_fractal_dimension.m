function [mean_FD, std_FD, FD_vals] = mean_fractal_dimension(data_folder, k_max)
% =========================================================================
% MEAN_FRACTAL_DIMENSION 
% Computes the average Higuchi Fractal Dimension (FD) and standard 
% deviation for all .mat time series files stored in a specified directory.
%
% Inputs:
%   data_folder : String or char array specifying the path to the directory.
%   k_max       : Maximum interval time (k_max parameter for Higuchi FD).
%                 
% Outputs:
%   mean_FD     : Mean fractal dimension across all valid .mat files.
%   std_FD      : Standard deviation of the fractal dimension across files.
%   FD_vals     : Vector containing the computed fractal dimension for each file.
%
% Example usage:
%   [mu, sigma, vals] = mean_fractal_dimension('./data_folder', 10);
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
    FD_temp = zeros(num_files, 1);
    fprintf('\nProcessing %d files in folder: %s...\n', num_files, data_folder);

    valid_count = 0;
    
    % Loop through files and compute Higuchi Fractal Dimension
    for k = 1:num_files
        filename = file_list(k).name;
        file_path = fullfile(data_folder, filename);

        try
            % Load time series data from .mat file
            loaded_data = load(file_path);
            data_cells = struct2cell(loaded_data);

            if isempty(data_cells)
                warning('File %s is empty. Skipping.', filename);
                continue;
            end

            % Extract primary numerical vector
            signal = data_cells{1}(:);

            % Call external Higuchi_FD function
            FD = Higuchi_FD(k_max, signal);
            
            valid_count = valid_count + 1;
            FD_temp(valid_count) = FD;
            fprintf('  [%d/%d] %s -> Fractal Dimension: %.6f\n', k, num_files, filename, FD);
        catch ME
            warning('Failed to compute fractal dimension for %s: %s', filename, ME.message);
        end
    end

    if valid_count == 0
        error('No valid .mat files were successfully processed.');
    end

    % Compute statistics on valid outputs
    FD_vals = FD_temp(1:valid_count);
    mean_FD = mean(FD_vals);
    std_FD  = std(FD_vals);

    % Print Summary
    fprintf('\n----------------------------------------\n');
    fprintf('Completed (%d/%d valid files processed)\n', valid_count, num_files);
    fprintf('Mean Fractal Dimension : %.6f\n', mean_FD);
    fprintf('Standard Deviation     : %.6f\n', std_FD);
    fprintf('----------------------------------------\n');
end