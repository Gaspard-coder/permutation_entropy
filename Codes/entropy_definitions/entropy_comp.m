function [regular_e, renyi_list, tsalis_list] = entropy_comp(y,m,t,a_array, q_array)
% =========================================================================
% Computation and comparison of permutation, Rényi, and Tsallis entropy
% =========================================================================
%
% Input:
%   y        : 1-dimensional input signal
%   m        : embedding dimension
%   t        : time delay
%   a_array  : Rényi entropy parameter values to test
%   q_array  : Tsallis entropy parameter values to test
%
% Output:
%   regular_e  : permutation entropy of the signal
%   renyi_list : Rényi entropy values corresponding to a_array
%   tsalis_list: Tsallis entropy values corresponding to q_array
%
% The function computes the permutation entropy, Rényi entropy for each
% value in a_array, and Tsallis entropy for each value in q_array.
% It also plots the three entropy measures for comparison.
%
% Exemple:
%   [pe, renyi, tsalis] = entropy_comp(y, 5, 1, 0.5:0.5:3, 0.5:0.5:3);
% =========================================================================

regular_e = permentropy_opti(y,m,t);
renyi_list = zeros(size(a_array));
tsalis_list = zeros(size(q_array));

for i = 1:numel(a_array)
    a = a_array(i);
    [~,renyi_list(i)] = renyi_entropy(y,m,t,a);
end

for j = 1:numel(q_array)
    q = q_array(j);
    [~,tsalis_list(j)] = tsalis_entropy(y,m,t,q);
end

figure;

plot(a_array, renyi_list, 'o-', 'LineWidth', 1.5);
hold on;

plot(q_array, tsalis_list, 's-', 'LineWidth', 1.5);

% Horizontal line for regular_e
yline(regular_e, '--', 'Permutation entropy', 'LineWidth', 1.5);

hold off;

xlabel('Parameter');
ylabel('Entropy');
title('Permutation, Rényi and Tsallis entropy');
legend('Rényi entropy', 'Tsallis entropy', 'Permutation entropy', ...
       'Location', 'best');
grid on;

end