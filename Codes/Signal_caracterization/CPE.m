function [cpe] = CPE(file1, file2, m, t, var1, var2)
% =========================================================================
% CPE Computes Conditional Permutation Entropy H(Y|X)
% from a signal X to a signal Y stored in .mat files.
%
% Formula: H(Y|X) = H(X, Y) - H(X)
%
% Inputs:
%   file1 - Path to source .mat file (Signal X)
%   file2 - Path to target .mat file (Signal Y)
%   m     - Embedding dimension
%   t     - Embedding time delay / lag parameter
%   var1  - (Optional) Variable name inside file1
%   var2  - (Optional) Variable name inside file2
%
% Output:
%   cpe   - Conditional Permutation Entropy H(Y|X) (in bits)
% =========================================================================

if nargin < 5, var1 = ''; end
if nargin < 6, var2 = ''; end

[~, h_x, ~, h_xy] = perm_mutual_info(file1, file2, m, t, var1, var2);

% Compute Conditional Permutation Entropy H(Y|X)
cpe = h_xy - h_x;

end