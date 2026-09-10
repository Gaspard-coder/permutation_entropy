function outputFolder = f_resample(inputFolder, step)
%F_RESAMPLE Downsample all .mat time-series files in a folder.
%
%   outputFolder = f_resample(inputFolder, step)
%
% INPUT
%   inputFolder  - folder containing .mat files
%   step - integer decimation factor
%
%                  Example:
%                  step = 15
%
%                  keeps one sample every 15 original samples:
%                  1, 16, 31, 46, ...
%
% OUTPUT
%   outputFolder - folder containing the resampled .mat files
%
% Example:
%
%   outputFolder = f_resample('MAT\DBT2', 15);
%
% This creates:
%
%   MAT\DBT2_resampled_15\
%
% with the resampled .mat files.
%
% IMPORTANT:
%   This function performs DECIMATION. It does not interpolate or
%   average values. NaNs are preserved.
%
%   For a series sampled every minute:
%       step = 15
%   produces approximately one sample every 15 minutes.

%% Validate input arguments

if nargin < 2
    error('Usage: f_resample(inputFolder, step)');
end

if ~isfolder(inputFolder)
    error('Input folder does not exist: %s', inputFolder);
end

if ~isscalar(step) || ...
        ~isnumeric(step) || ...
        ~isfinite(step) || ...
        step < 1 || ...
        step ~= round(step)

    error('step must be a positive integer.');
end

step = round(step);

%% Create output folder

[parentFolder, folderName] = fileparts(inputFolder);

if isempty(parentFolder)
    parentFolder = pwd;
end

outputFolder = fullfile( ...
    parentFolder, ...
    sprintf('%s_resampled_%d', folderName, step));

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

fprintf('\nResampling folder:\n');
fprintf('  Input : %s\n', inputFolder);
fprintf('  Output: %s\n', outputFolder);
fprintf('  Factor: %d\n\n', step);

%% Find .mat files

files = dir(fullfile(inputFolder, '*.mat'));

if isempty(files)
    warning('No .mat files found in %s', inputFolder);
    return;
end

%% Process every file

for k = 1:numel(files)

    inputFile = fullfile(files(k).folder, files(k).name);
    outputFile = fullfile(outputFolder, files(k).name);

    fprintf('[%d/%d] %s\n', ...
        k, numel(files), files(k).name);

    %% Load file

    S = load(inputFile);

    %% Determine number of samples
    %
    % Prefer datos.libre_gl when available because this is the
    % standard CGMacros Libre glucose time series.

    if isfield(S, 'datos') && isfield(S.datos, 'libre_gl')

        nSamples = numel(S.datos.libre_gl);

    elseif isfield(S, 'libre_gl')

        nSamples = numel(S.libre_gl);

    else
        % Try to find the first numeric vector in the MAT file

        variables = fieldnames(S);
        nSamples = [];

        for v = 1:numel(variables)

            value = S.(variables{v});

            if isnumeric(value) && isvector(value)
                nSamples = numel(value);
                break;
            end

        end

        if isempty(nSamples)
            warning('No time-series vector found. Skipping %s.', ...
                files(k).name);
            continue;
        end
    end

    %% Indices to keep
    %
    % Example for step = 15:
    %
    % 1, 16, 31, 46, ...

    idx = 1:step:nSamples;

    %% Resample structure

    S_resampled = resampleStruct(S, idx, nSamples);

    %% Save

    save(outputFile, '-struct', 'S_resampled', '-v7');

    fprintf('    Original samples : %d\n', nSamples);
    fprintf('    Resampled samples: %d\n', numel(idx));
    fprintf('    Saved: %s\n', outputFile);
end

fprintf('\nDone.\n');
fprintf('Output folder:\n%s\n\n', outputFolder);

end


%% ========================================================================
function S_out = resampleStruct(S_in, idx, nSamples)
%RESAMPLESTRUCT Recursively decimate time-series vectors.

S_out = S_in;

fields = fieldnames(S_in);

for i = 1:numel(fields)

    name = fields{i};
    value = S_in.(name);

    %% Numeric vector

    if isnumeric(value) && isvector(value)

        if numel(value) == nSamples
            S_out.(name) = value(idx);
        end

        %% Cell vector

    elseif iscell(value) && isvector(value)

        if numel(value) == nSamples
            S_out.(name) = value(idx);
        end

        %% Character vector
        %
        % Character strings are metadata, not time series.

    elseif ischar(value)

        S_out.(name) = value;

        %% Struct

    elseif isstruct(value)

        S_out.(name) = resampleStructArray(value, idx, nSamples);

    end
end

end


%% ========================================================================
function S_out = resampleStructArray(S_in, idx, nSamples)
%RESAMPLESTRUCTARRAY Recursive handling of structures.

S_out = S_in;

% Scalar structure

if isscalar(S_in)

    fields = fieldnames(S_in);

    for i = 1:numel(fields)

        name = fields{i};
        value = S_in.(name);

        if isnumeric(value) && isvector(value)

            if numel(value) == nSamples
                S_out.(name) = value(idx);
            end

        elseif iscell(value) && isvector(value)

            if numel(value) == nSamples
                S_out.(name) = value(idx);
            end

        elseif isstruct(value)

            S_out.(name) = ...
                resampleStructArray(value, idx, nSamples);

        end
    end

else
    % Non-scalar struct: do not alter it automatically because it may
    % represent independent metadata records rather than a time axis.

    S_out = S_in;
end

end

