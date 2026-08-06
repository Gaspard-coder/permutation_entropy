function r_array = characterize_m(file,m_array,t_array)
% =======
% Documentation
% 
% 
% =========

r_array = param_computing(file, m_array, t_array);
 
disp('t   m   pe        pe2       pe2_norm   t_compute');
disp(r_array);
 
plot(r_array(:,2), r_array(:,6), '-o', 'LineWidth', 1.5);
xlabel('m');
ylabel('Computing time (s)');
title(sprintf('Computing time vs m (t = %d) - %s', t_array, file));
grid on;
