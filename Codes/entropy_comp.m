function [regular_e, renyi_list, tsalis_list] = entropy_comp(y,m,t,a_array, q_array)
% ==============
% Documentation
% ==============

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