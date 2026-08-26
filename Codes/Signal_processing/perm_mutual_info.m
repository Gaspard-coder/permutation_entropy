function [mi, h_x, h_y, h_xy] = perm_mutual_info(file1, file2, m, t, var1, var2)
% =========================================================================
% Calculates Permutation Mutual Information between signals
% stored in two separate .mat files using Bandt & Pompe (2002) ordering.
%
% Inputs:
%   file1 - Path to the first .mat file (containing signal X)
%   file2 - Path to the second .mat file (containing signal Y)
%   m     - Embedding dimension / order of permutation
%   t     - Time delay / lag parameter 
%   var1  - (Optional) Name of variable inside file1
%   var2  - (Optional) Name of variable inside file2
%
% Outputs:
%   mi    - Permutation Mutual Information in bits: I(X;Y) = H(X) + H(Y) - H(X,Y)
%   h_x   - Marginal permutation entropy of signal X (bits)
%   h_y   - Marginal permutation entropy of signal Y (bits)
%   h_xy  - Joint permutation entropy of signals X and Y (bits)
%
% NB: all entropies here are calculated using log2
% =========================================================================

% Load variables from .mat files
data1 = load(file1);
data2 = load(file2);

if nargin < 5 || isempty(var1)
    fields1 = fieldnames(data1);
    x = data1.(fields1{1});
else
    x = data1.(var1);
end

if nargin < 6 || isempty(var2)
    fields2 = fieldnames(data2);
    y = data2.(fields2{1});
else
    y = data2.(var2);
end

% Ensure column vectors and align lengths
x = x(:); 
y = y(:);
N = min(length(x), length(y));
x = x(1:N);
y = y(1:N);

% Number of delay embedding vectors
nV = N - t * (m - 1);
if nV <= 0
    error('Signal length is too short for the chosen embedding dimension and delay.');
end

% Construct vector index matrix (vectorized extraction)
offsets = (0:t:t*(m-1))'; 
starts  = 1:nV;           
idx     = offsets + starts; 

% Ordinal pattern generation for X and Y
[~, IV_x] = sort(x(idx), 1);
IV_x = IV_x'; % nV x m

[~, IV_y] = sort(y(idx), 1);
IV_y = IV_y'; % nV x m

% Match patterns against the full theoretical set of permutations
all_patterns = perms(1:m);
num_patterns = factorial(m);

[~, pattern_idx_x] = ismember(IV_x, all_patterns, 'rows');
[~, pattern_idx_y] = ismember(IV_y, all_patterns, 'rows');

% Build 2D joint histogram of shape (m! x m!)
c_xy = accumarray([pattern_idx_x, pattern_idx_y], 1, [num_patterns, num_patterns]);
p_xy = c_xy / nV;

% Derive marginal probability distributions
p_x = sum(p_xy, 2);
p_y = sum(p_xy, 1)';

% Filter out non-positive entries for entropy calculation
px_pos  = p_x(p_x > 0);
py_pos  = p_y(p_y > 0);
pxy_pos = p_xy(p_xy > 0);

% Calculate marginal and joint Permutation Entropies (in bits)
h_x  = -sum(px_pos .* log2(px_pos));
h_y  = -sum(py_pos .* log2(py_pos));
h_xy = -sum(pxy_pos .* log2(pxy_pos));

% Mutual Information computation
mi = h_x + h_y - h_xy;
end