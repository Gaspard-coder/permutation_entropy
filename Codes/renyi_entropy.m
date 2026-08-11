function [S, H] = renyi_entropy(y, m, t, a)
% =========================================================================
% Computes the Renyi entropy of order "a" (alpha) of a time series y
% =========================================================================
% Inputs:
%   y : vector, the time series to analyze
%   m : positive integer, embedding dimension (pattern length).
%   t : positive integer, embedding delay (time lag) between successive
%       points of a pattern.
%   a : positive real, Renyi order (alpha), a > 0. a = 1 is handled as
%       the Shannon-entropy limiting case.
%
% Outputs:
%   S : Renyi entropy S_a[P], computed with the natural logarithm (ln)
%   H : Normalized Renyi entropy, H = S_a[P] / ln(m!), ranging in [0, 1].
%
% Example:
%   x = [4, 7, 9, 10, 6, 11, 3];
%   [S, H] = renyi_entropy(x, 3, 1, 4);
% =========================================================================

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

% Counting occurrences of each distinct permutation
[~,~,ic] = unique(IV,'rows');
c = accumarray(ic,1);

% Empirical probability distribution of the permutations
p = c / sum(c);

% Renyi entropy (ln version)
if a == 1
    S = -sum(p .* log(p)); %Shannon limit
else
    S = (1/(1-a)) * log(sum(p.^a));
end

% Normalized Renyi entropy
H = S / log(factorial(m));

end
