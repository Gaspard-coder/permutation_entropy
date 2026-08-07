function [pe2_normalized lambda] = guess_sig(file,m_array,t_array)

% ===
% Comments
% ===

% pe2_normalized computing (shorten version of param_computing_opti)
data= load(file);
fields= fieldnames(data);
S = data.(fields{1});
nT = length(t_array);
nM = length(m_array);
r_array = zeros(nT*nM, 3); 
 
row = 0;
for t = t_array
    for m = m_array
        row = row + 1;
        [~, ~, pe2_normalized] = permentropy_opti(S,m,t);
        r_array(row,1) = t;
        r_array(row,2) = m;
        r_array(row,3) = pe2_normalized;
    end
end

% Calculating lyapunovExponent
lambda = lyapunovExponent(S,1); % for synthetic signal fs=1


%Display
disp('       t        m       pe2_norm');
disp(r_array);
disp(['Lyapunov exponent = ', num2str(lambda)]);