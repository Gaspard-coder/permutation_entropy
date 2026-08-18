function [S, H] = tsalis_entropy(y, m, t, q)
% =========================================================================
% Computes the tsalis entropy of order "a" (alpha) of a time series y
% =========================================================================
% Inputs:
%   y : vector, the time series to analyze
%   m : positive integer, embedding dimension (pattern length).
%   t : positive integer, embedding delay (time lag) between successive
%       points of a pattern.
%   q : positive real, tsalis order 
%
% Outputs:
%   S : tsalis entropy S_q[P]
%   H : Normalized tsalis entropy, ranging in [0, 1].
%
% Example:
%   x = [4, 7, 9, 10, 6, 11, 3];
%   [S, H] = tsalis_entropy(x, 3, 1, 4);
% =========================================================================

% Ensure column vector
y = y(:);

ly = length(y);
nV = ly - t*(m-1);   % Number of vectors

% Building the vectors 
offsets = (0:t:t*(m-1))';   
starts  = 1:nV;              
idx = offsets + starts;     
Y = y(idx);                  

% Computing ordinal patterns
[~, IV] = sort(Y,1);
IV = IV';   % nV x m, a row = a permutation vector

% CORRECTION: Map to all possible m! patterns
all_patterns = perms(1:m); 
num_patterns = factorial(m);

[~, pattern_idx] = ismember(IV, all_patterns, 'rows');
c = accumarray(pattern_idx, 1, [num_patterns, 1]);

% Empirical probability distribution (includes zeros)
p = c / sum(c);
if q == 1
    % Shannon limit
    p_pos = p(p > 0);
    S = -sum(p_pos .* log(p_pos)); 
    S_max = log(num_patterns);
else
    % Tsallis entropy
    S = (1/(q-1)) * (1 - sum(p.^q));
    % Correct Tsallis maximum for uniform distribution
    S_max = (1 - num_patterns^(1-q)) / (q-1);
end

% Normalized Tsallis entropy
H = S / S_max;

end