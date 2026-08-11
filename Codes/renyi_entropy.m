function [S, H] = renyi_entropy(y, m, t, a)
% =========================================================================
% RENYI_ENTROPY  Renyi permutation entropy of a time series
% =========================================================================
%
% DESCRIPTION
%   Computes the Renyi entropy of order "a" (alpha) of a time series y,
%   using the ordinal-pattern probability distribution introduced by
%   Bandt & Pompe (2002), the same approach as in permentropy_opti.m.
%
%   For each of the (N - t*(m-1)) length-m overlapping subsequences of y
%   (with delay t), the ordinal pattern (permutation) is determined and
%   the empirical probability p_i of each of the m! possible patterns is
%   estimated as p_i = (# occurrences of pattern i) / (N - m + 1).
%
%   The Renyi entropy of order a of this distribution P = {p_i} is then:
%
%           S_a[P] = 1/(1-a) * ln( sum_i p_i^a ),      a > 0, a ~= 1
%
%   and its normalized version (dividing by the maximum possible entropy,
%   ln(m!), obtained for the uniform distribution over all permutations):
%
%           H_a[P] = S_a[P] / ln(m!)
%
%   When a -> 1, the Renyi entropy converges to the Shannon entropy:
%
%           S_1[P] = - sum_i p_i * ln(p_i)
%
%   This function reproduces the "Renyi entropy" (RE) feature used in
%   Ziccardi, Rey & Legnani, "ECG Signals Classification Using
%   Overlapping Variables to Detect Atrial Fibrillation", Trends Comput.
%   Appl. Math., 23, N.3 (2022), where m=5, t=5 and a=4 were used.
%
% -------------------------------------------------------------------------
% INPUTS
%   y : vector, the time series to analyze
%   m : positive integer, embedding dimension (pattern length).
%       Must satisfy length(y) > t*(m-1) so that at least one vector can
%       be built. m! should stay small enough for practical computation
%       (m = 3..7 typical).
%   t : positive integer, embedding delay (time lag) between successive
%       points of a pattern.
%   a : positive real, Renyi order (alpha), a > 0. a = 1 is handled as
%       the Shannon-entropy limiting case.
%
% OUTPUTS
%   S : Renyi entropy S_a[P], computed with the natural logarithm (ln),
%       expressed in nats.
%   H : Normalized Renyi entropy, H = S_a[P] / ln(m!), ranging in [0, 1].
%
% -------------------------------------------------------------------------
% EXAMPLE
%   x = [4, 7, 9, 10, 6, 11, 3];
%   [S, H] = renyi_entropy(x, 3, 1, 4);
%   % S  -> Renyi entropy of order 4 of the ordinal-pattern distribution
%   % H  -> same entropy normalized by ln(3!) = ln(6)
%
%   % Reproducing the paper's ECG feature settings (m=5, t=5, alpha=4):
%   [S, H] = renyi_entropy(ecg_signal, 5, 5, 4);
%
% =========================================================================

ly = length(y);
nV = ly - t*(m-1);   % Number of vectors

% Building the vectors (vectorized, as in permentropy_opti.m)
offsets = (0:t:t*(m-1))';   % m x 1
starts  = 1:nV;              % 1 x nV
idx = offsets + starts;      % m x nV (broadcasting)
Y = y(idx);                  % each column is a vector to study

% Computing ordinal patterns
[~, IV] = sort(Y,1);
IV = IV';   % nV x m, a row = a permutation vector

% Counting occurrences of each distinct permutation
[~,~,ic] = unique(IV,'rows');
c = accumarray(ic,1);

% Empirical probability distribution of the permutations
p = c / sum(c);

% Renyi entropy (natural log), with Shannon limit at a = 1
if a == 1
    S = -sum(p .* log(p));
else
    S = (1/(1-a)) * log(sum(p.^a));
end

% Normalized Renyi entropy (max entropy = ln(m!), uniform distribution)
H = S / log(factorial(m));

end
