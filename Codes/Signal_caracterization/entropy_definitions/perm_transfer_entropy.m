function [te] = perm_transfer_entropy(file1,file2,m,t,var1,var2)
% =========================================================================
% Calculates Permutation Transfer Entropy between signals
% stored in two separate .mat files using Bandt & Pompe (2002) ordering.
%
% Inputs:
%   file1 - Path to the first .mat file (containing signal X)
%   file2 - Path to the second .mat file (containing signal Y)
%   m     - Embedding dimension / order of permutation
%   t     - Time delay / lag parameter (used for embedding and tau lag)
%   var1  - (Optional) Name of variable inside file1
%   var2  - (Optional) Name of variable inside file2
%
% Outputs:
%   te    - Permutation transfer entropy (X -> Y)
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

% =========================================================================
% TRANSFER ENTROPY CALCULATION (tau = t)
% =========================================================================
tau = t;

if nV <= tau
    error('Not enough embedded pattern samples for the requested lag tau = %d.', tau);
end

% Index sequences according to Eq(5) with tau = t:
% vi     = pattern_idx_y at time i     ( indices: tau+1 to nV )
% vi_1   = pattern_idx_y at time i-1   ( indices: tau to nV-1 )
% ui_tau = pattern_idx_x at time i-tau ( indices: 1 to nV-tau )
vi     = pattern_idx_y((tau + 1):end);
vi_1   = pattern_idx_y(tau:(end - 1));
ui_tau = pattern_idx_x(1:(end - tau));

P = length(vi); % Total number of data triplets

% Build 3D joint histogram of shape (m! x m! x m!)
c_3d = accumarray([vi, vi_1, ui_tau], 1, [num_patterns, num_patterns, num_patterns]);
p_3d = c_3d / P;

% Pre-calculate marginal distributions
p_v_past        = sum(p_3d, [1, 3]);   % p(vi_1)
p_v_past_u_past = sum(p_3d, 1);        % p(vi_1, ui_tau)
p_v_curr_v_past = sum(p_3d, 3);        % p(vi, vi_1)

% Find non-zero entries for Transfer Entropy summation
idx_nz = find(p_3d > 0);
[i1, i2, i3] = ind2sub(size(p_3d), idx_nz);

te = 0;
for k = 1:length(idx_nz)
    curr_y = i1(k); % v_i
    past_y = i2(k); % v_{i-1}
    past_x = i3(k); % u_{i-tau}
    
    p_xyz = p_3d(curr_y, past_y, past_x);
    p_y1  = p_v_past(1, past_y, 1);
    p_xy1 = p_v_past_u_past(1, past_y, past_x);
    p_yy1 = p_v_curr_v_past(curr_y, past_y);
    
    % Term: (p(vi, vi_1, ui_tau) * p(vi_1)) / (p(vi_1, ui_tau) * p(vi, vi_1))
    term = (p_xyz * p_y1) / (p_xy1 * p_yy1);
    
    te = te + p_xyz * log2(term);
end

end