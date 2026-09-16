function convert_mat_table_to_double(inputFolder, outputFolder)
% CONVERT_MAT_TABLE_TO_DOUBLE Converts tables inside .mat files into double matrices or vectors.
%
% Usage:
%   convert_mat_table_to_double()
%   convert_mat_table_to_double(inputFolder, outputFolder)

if nargin < 1 || isempty(inputFolder)
    inputFolder = pwd;
end

if nargin < 2 || isempty(outputFolder)
    outputFolder = fullfile(inputFolder, 'double_files');
end

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

files = dir(fullfile(inputFolder, '*.mat'));
if isempty(files)
    fprintf('No .mat files found in: %s\n', inputFolder);
    return;
end

for k = 1:length(files)
    filePath = fullfile(files(k).folder, files(k).name);
    S = load(filePath);

    fields = fieldnames(S);
    converted = false;

    for v = 1:numel(fields)
        val = S.(fields{v});

        if istable(val)
            % Extract numeric columns from the table using 'uniform' output format
            numericCols = varfun(@isnumeric, val, 'OutputFormat', 'uniform');

            if any(numericCols)
                % Convert numeric columns to a double matrix/vector
                doubleData = double(table2array(val(:, numericCols)));

                % Save the 'doubleData' variable into the output .mat file
                outputPath = fullfile(outputFolder, files(k).name);
                save(outputPath, 'doubleData');

                fprintf('Converted [%d/%d]: %s -> double (%d x %d)\n', ...
                    k, length(files), files(k).name, size(doubleData, 1), size(doubleData, 2));
                converted = true;
                break;
            end
        end
    end

    if ~converted
        fprintf('Warning: No numeric table found in %s\n', files(k).name);
    end
end

fprintf('\nConversion complete: %d file(s) saved to "%s".\n', length(files), outputFolder);
end