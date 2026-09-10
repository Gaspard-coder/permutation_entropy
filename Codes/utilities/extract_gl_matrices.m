function extract_gl_matrices(inputFolder)
% EXTRACT_GL_MATRICES Extract libre_gl and dexcom_gl from all MAT files.
%
%   extract_gl_matrices(inputFolder)
%
%   For each MAT file in inputFolder, the function extracts:
%       datos.libre_gl
%       datos.dexcom_gl
%
%   The matrices are saved as separate MAT files in:
%       extracted/libre/
%       extracted/dexcom/
%
%   Example:
%       extract_gl_matrices('/home/user/data');

% Check input folder
if ~isfolder(inputFolder)
    error('The specified input folder does not exist: %s', inputFolder);
end

% Find all MAT files
files = dir(fullfile(inputFolder, '*.mat'));

if isempty(files)
    warning('No MAT files found in: %s', inputFolder);
    return;
end

% Create output folders
extractedFolder = fullfile(inputFolder, 'extracted');
libreFolder = fullfile(extractedFolder, 'libre');
dexcomFolder = fullfile(extractedFolder, 'dexcom');

if ~isfolder(libreFolder)
    mkdir(libreFolder);
end

if ~isfolder(dexcomFolder)
    mkdir(dexcomFolder);
end

% Process each MAT file
for k = 1:numel(files)

    inputFile = fullfile(files(k).folder, files(k).name);

    fprintf('Processing: %s\n', files(k).name);

    % Load the MAT file
    data = load(inputFile);

    % Check that "datos" exists
    if ~isfield(data, 'datos')
        warning('Skipping %s: variable "datos" not found.', files(k).name);
        continue;
    end

    % Check required fields
    if ~isfield(data.datos, 'libre_gl')
        warning('Skipping %s: "datos.libre_gl" not found.', files(k).name);
        continue;
    end

    if ~isfield(data.datos, 'dexcom_gl')
        warning('Skipping %s: "datos.dexcom_gl" not found.', files(k).name);
        continue;
    end

    % Extract the matrices
    libre_gl = data.datos.libre_gl;
    dexcom_gl = data.datos.dexcom_gl;

    % Get original file name without extension
    [~, fileName, ~] = fileparts(files(k).name);

    % Define output file names
    libreFile = fullfile(libreFolder, ...
        [fileName '_libre_gl.mat']);

    dexcomFile = fullfile(dexcomFolder, ...
        [fileName '_dexcom_gl.mat']);

    % Save each matrix separately
    save(libreFile, 'libre_gl');
    save(dexcomFile, 'dexcom_gl');

    fprintf('  Saved libre_gl: %s\n', libreFile);
    fprintf('  Saved dexcom_gl: %s\n', dexcomFile);
end

fprintf('\nExtraction completed.\n');
fprintf('Output folder: %s\n', extractedFolder);
end

