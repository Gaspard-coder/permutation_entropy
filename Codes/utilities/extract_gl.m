function outputFile = extract_gl(inputFile, outputFile)
%EXTRACT_LIBRE_GL Extract FreeStyle Libre glucose time series from CGMacros .mat
%
%   outputFile = extract_libre_gl(inputFile)
%   outputFile = extract_libre_gl(inputFile, outputFile)
%
% INPUT
%   inputFile  - path to a CGMacros .mat file, e.g.
%                'MAT\DBT2\CGMacros-035.mat'
%
%   outputFile - optional path for the output .mat file.
%                If omitted, "_libre.mat" is appended to the input name.
%
% OUTPUT
%   outputFile - path of the generated .mat file.
%
% The generated file contains:
%   libre_gl    - Libre glucose [mg/dL], Nx1
%   t_min       - minutes from the first sample, Nx1
%   datenum     - MATLAB datenum timestamp, Nx1
%   timestamp   - timestamp strings, if available
%   fecha       - MATLAB datetime representation
%   sujeto      - subject metadata, if available
%
% Example:
%   extract_libre_gl('MAT\DBT2\CGMacros-035.mat');
%
%   extract_libre_gl( ...
%       'MAT\DBT2\CGMacros-035.mat', ...
%       'MAT\DBT2\CGMacros-035_libre.mat');

%% Check input
if nargin < 1 || isempty(inputFile)
    error('You must provide an input .mat file.');
end

if ~isfile(inputFile)
    error('Input file does not exist: %s', inputFile);
end

[folder, name, ext] = fileparts(inputFile);

if ~strcmpi(ext, '.mat')
    error('Input file must have extension .mat');
end

%% Define output file
if nargin < 2 || isempty(outputFile)
    outputFile = fullfile(folder, [name '_libre.mat']);
end

%% Load file
S = load(inputFile);

%% Check expected structure
if ~isfield(S, 'datos')
    error('The file does not contain the expected variable "datos".');
end

if ~isfield(S.datos, 'libre_gl')
    error('The structure "datos" does not contain "libre_gl".');
end

%% Extract Libre glucose
libre_gl = S.datos.libre_gl(:);

%% Extract time
if isfield(S.datos, 't_min')
    t_min = S.datos.t_min(:);
else
    error('The structure "datos" does not contain "t_min".');
end

%% Extract MATLAB datenum
if isfield(S.datos, 'datenum')
    datenum = S.datos.datenum(:);
    fecha = datetime(datenum, 'ConvertFrom', 'datenum');
else
    datenum = [];
    fecha = datetime.empty(size(libre_gl));
end

%% Optional timestamp field
if isfield(S.datos, 'timestamp')
    timestamp = S.datos.timestamp(:);
else
    timestamp = {};
end

%% Check dimensions
N = numel(libre_gl);

if numel(t_min) ~= N
    error(['Size mismatch: libre_gl has %d samples but t_min has %d samples.'], ...
        N, numel(t_min));
end

if ~isempty(datenum) && numel(datenum) ~= N
    error(['Size mismatch: libre_gl has %d samples but datenum has %d samples.'], ...
        N, numel(datenum));
end

%% Subject metadata, when available
if isfield(S, 'sujeto')
    sujeto = S.sujeto;
else
    sujeto = struct();
end

%% Save extracted series
save(outputFile, ...
    'libre_gl', ...
    't_min', ...
    'datenum', ...
    'fecha', ...
    'timestamp', ...
    'sujeto', ...
    '-v7');

%% Report
nValid = sum(~isnan(libre_gl));

fprintf('Libre glucose extracted successfully.\n');
fprintf('Input : %s\n', inputFile);
fprintf('Output: %s\n', outputFile);
fprintf('Samples: %d\n', N);
fprintf('Valid Libre samples: %d (%.2f%%)\n', ...
    nValid, 100*nValid/N);

if ~isempty(datenum)
    fprintf('Start: %s\n', datestr(fecha(1)));
    fprintf('End  : %s\n', datestr(fecha(end)));
end
end

