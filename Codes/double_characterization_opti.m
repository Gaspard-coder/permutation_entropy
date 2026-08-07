function r_array = double_characterization_opti(file,m_array,t_array)
% =========================================================================
% Characterization of the effect of different values of m and t
% =========================================================================
%
% Input:
%   file     : .mat file with the signal (1-dimension)
%   m_array  : m values to test
%   t_array  : t values to test
%
% Output:
%   r_array  : param_computing output: [t m pe pe2 pe2_normalized t_compute]
%   plot computing normalize permutation entropy vs m (one curve per t)
%
% Exemple:
%   double_characterization('signal.mat', 3:8, [1 2 4]);
% =========================================================================

r_array = param_computing_opti(file, m_array, t_array);

disp('         t        m         pe       pe2    pe2_norm   t_compute');
disp(r_array);

figure;
hold on;
for t = t_array
    rows = r_array(:,1) == t;
    plot(r_array(rows,2), r_array(rows,5), '-o', 'LineWidth', 1.5, ...
         'DisplayName', sprintf('t = %d', t));
end
hold off;

xlabel('m');
ylabel('Normalized entropy ');
title(sprintf('Normalized entropy vs m and t - %s', file));
legend('show', 'Location', 'northwest');
grid on;

end
