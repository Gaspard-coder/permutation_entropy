function [regular_e, H_list] = entropy_comp(y,m,t,a_array)
% ==============
% Documentation
% ==============

regular_e = permentropy_opti(y,m,t);
H_list = zeros(size(a_array));

for i = 1:numel(a_array)
    a = a_array(i);
    [~,H_list(i)] = renyi_entropy(y,m,t,a);
end

figure;
plot(a_array, H_list, 'o-', 'LineWidth', 1.5);
hold on;

% Horizontal line for regular_e
yline(regular_e, '--', 'Permutation entropy', 'LineWidth', 1.5);

hold off;

xlabel('\alpha');
ylabel('Entropy');
title('Permutation entropy vs Rényi entropy');
legend('Rényi entropy', 'Permutation entropy', 'Location', 'best');
grid on;

end