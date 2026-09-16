function outputFolder = f_resample(inputFolder, step)
%F_RESAMPLE Downsample all .mat time-series files in a folder.

if nargin < 2
    error('Usage: f_resample(inputFolder, step)');
end

if ~isfolder(inputFolder)
    error('Input folder does not exist: %s', inputFolder);
end

if ~isscalar(step) || ~isnumeric(step) || ~isfinite(step) || step < 1 || step ~= round(step)
    error('step must be a positive integer.');
end

step = round(step);

[parentFolder, folderName] = fileparts(inputFolder);
if isempty(parentFolder)
    parentFolder = pwd;
end

outputFolder = fullfile(parentFolder, sprintf('%s_resampled_%d', folderName, step));
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

fprintf('\nResampling folder:\n');
fprintf('  Input : %s\n', inputFolder);
fprintf('  Output: %s\n', outputFolder);
fprintf('  Factor: %d\n\n', step);

files = dir(fullfile(inputFolder, '*.mat'));
if isempty(files)
    warning('No .mat files found in %s', inputFolder);
    return;
end

for k = 1:numel(files)
    inputFile = fullfile(files(k).folder, files(k).name);
    outputFile = fullfile(outputFolder, files(k).name);

    fprintf('[%d/%d] %s\n', k, numel(files), files(k).name);

    S = load(inputFile);

    %% Determine number of samples
    if isfield(S, 'datos') && isfield(S.datos, 'libre_gl')
        nSamples = numel(S.datos.libre_gl);
    elseif isfield(S, 'libre_gl')
        nSamples = numel(S.libre_gl);
    else
        variables = fieldnames(S);
        nSamples = [];

        for v = 1:numel(variables)
            value = S.(variables{v});

            if isnumeric(value) && isvector(value)
                nSamples = numel(value);
                break;
            elseif istable(value)
                nSamples = height(value);
                break;
            end
        end

        if isempty(nSamples)
            warning('No time-series vector found. Skipping %s.', files(k).name);
            continue;
        end
    end

    %% Indices to keep
    idx = 1:step:nSamples;

    %% Resample structure / table
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
S_out = S_in;
fields = fieldnames(S_in);

for i = 1:numel(fields)
    name = fields{i};
    value = S_in.(name);

    if istable(value)
        if height(value) == nSamples
            S_out.(name) = value(idx, :);
        end
    elseif isnumeric(value) && isvector(value)
        if numel(value) == nSamples
            S_out.(name) = value(idx);
        end
    elseif iscell(value) && isvector(value)
        if numel(value) == nSamples
            S_out.(name) = value(idx);
        end
    elseif ischar(value)
        S_out.(name) = value;
    elseif isstruct(value)
        S_out.(name) = resampleStructArray(value, idx, nSamples);
    end
end
end


%% ========================================================================
function S_out = resampleStructArray(S_in, idx, nSamples)
S_out = S_in;

if isscalar(S_in)
    fields = fieldnames(S_in);

    for i = 1:numel(fields)
        name = fields{i};
        value = S_in.(name);

        if istable(value)
            if height(value) == nSamples
                S_out.(name) = value(idx, :);
            end
        elseif isnumeric(value) && isvector(value)
            if numel(value) == nSamples
                S_out.(name) = value(idx);
            end
        elseif iscell(value) && isvector(value)
            if numel(value) == nSamples
                S_out.(name) = value(idx);
            end
        elseif isstruct(value)
            S_out.(name) = resampleStructArray(value, idx, nSamples);
        end
    end
else
    S_out = S_in;
end
end