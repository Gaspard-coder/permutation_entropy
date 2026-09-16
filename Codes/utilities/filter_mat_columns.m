function filter_mat_columns(inputFolder, outputFolder, columnsToKeep)
% FILTER_MAT_COLUMNS Keeps only specified columns in .mat files containing double matrices.
%
% Usage:
%   filter_mat_columns(inputFolder, outputFolder, columnsToKeep)
%
% Example (keeps only the 1st and 3rd columns):
%   filter_mat_columns('Database/source', 'Database/filtered', [1, 3]);

if nargin < 3
    error('Usage: filter_mat_columns(inputFolder, outputFolder, columnsToKeep)');
end

% Create output folder if it doesn't exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Find all .mat files in the input folder
files = dir(fullfile(inputFolder, '*.mat'));
if isempty(files)
    fprintf('No .mat files found in: %s\n', inputFolder);
    return;
end

fprintf('Starting column filtering...\n\n');

for k = 1:length(files)
    inputPath = fullfile(files(k).folder, files(k).name);
    outputPath = fullfile(outputFolder, files(k).name);

    % Load the file content into a structure
    S = load(inputPath);
    fields = fieldnames(S);

    S_out = struct();
    modified = false;

    % Iterate through all variables inside the .mat file
    for v = 1:numel(fields)
        varName = fields{v};
        data = S.(varName);

        % Process if it's a numeric array/matrix
        if isnumeric(data)
            % Ensure the matrix has enough columns to avoid indexing errors
            if size(data, 2) >= max(columnsToKeep)
                % Keep only the requested columns
                S_out.(varName) = data(:, columnsToKeep);
                modified = true;
            else
                fprintf('Warning: %s (var: %s) has %d columns, cannot extract column %d. Skipping this variable.\n', ...
                    files(k).name, varName, size(data, 2), max(columnsToKeep));
                S_out.(varName) = data; % Keep original if error
            end
        else
            % Pass non-numeric variables (if any exist) through untouched
            S_out.(varName) = data;
        end
    end

    % Save only if we successfully modified something
    if modified
        % -struct saves the fields of S_out as individual variables,
        % preserving the exact original formatting.
        save(outputPath, '-struct', 'S_out');
        fprintf('Processed [%d/%d] : %s\n', k, length(files), files(k).name);
    end
end

fprintf('\nDone. Processed %d file(s) into "%s".\n', length(files), outputFolder);
end