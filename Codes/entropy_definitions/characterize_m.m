function r_array = characterize_m(file,m_array,t)
% =========================================================================
% Characterization of the effect of different values of m for a given t
% =========================================================================
%
% Input:
%   file     : .mat file with the signal (1-dimension)
%   m_array  : m values to test
%   t_array  : t value
%
% Output:
%   r_array  : param_computing output: [t m pe pe2 pe2_normalized t_compute]
%   plot of computing time vs m
%
% Exemple:
%   characterize_m('signal.mat', 3:8, 1);
% =========

r_array = param_computing(file, m_array, t);
 
disp('         t        m         pe         pe2     pe2_norm    t_compute');
disp(r_array);
 
plot(r_array(:,2), r_array(:,6), '-o', 'LineWidth', 1.5);
xlabel('m');
ylabel('Computing time (s)');
title(sprintf('Computing time vs m (t = %d) - %s', t, file));
grid on;
