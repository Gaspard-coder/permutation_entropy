function r_array = renyi_vs_m(file,m_array,t_array,a_array)

% ====
% For a given set of data display the influence of t, m and a coeff
% ===
% Inputs :
%     file: .mat file to study
%     m_array: embedding dimension array to study
%     t_array: embedding time delay array to study
%     a_array: a coefficients to try
% 
% Output:
%     r_array containing the normalized entropy [m t a pe_norm]
% ===

data= load(file);
fields= fieldnames(data);
y = data.(fields{1});
nT = length(t_array);
nM = length(m_array);
nA = length(a_array);
r_array = zeros(nT*nM*nA, 4);

row = 0;
for t = t_array
    for m = m_array
        for a = a_array
            row = row + 1;
            [~, H] = renyi_entropy(y, m, t, a);
            r_array(row,1) = t;
            r_array(row,2) = m;
            r_array(row,3) = a;
            r_array(row,4) = H;
        end
    end
end
disp('         t        m         a       pe_norm    ');
disp(r_array)

figure;
hold on;

for t = t_array
    for m = m_array
        % loop through (t, m) couple
        rows = (r_array(:,1) == t) & (r_array(:,2) == m);
        
        % plot pe_norm against a for a given (t,m) tuple
        plot(r_array(rows, 3), r_array(rows, 4), '-o', 'LineWidth', 1.5, ...
             'DisplayName', sprintf('t = %d, m = %d', t, m));
    end
end

hold off;
xlabel('\alpha ');
ylabel('Normalized Entropy');
title(sprintf('Normalized Renyi Entropy vs alpha  for combinations of t and m - %s', file), 'Interpreter', 'none');
legend('show', 'Location', 'best');
grid on;

end