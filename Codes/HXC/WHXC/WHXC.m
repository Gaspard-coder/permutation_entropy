function [wpe, wpe_2, wpe_norm, JSD, Comp_JS] = WHXC(data, m, t)
% =========================================================================
% Computes parameters of the Complexity-Entropy Causality (CEC) plane 
% using Weighted Permutation Entropy (WPE).
%
% Input:
%     data: one-dimensional vector (time series)
%     m: embedding dimension
%     t: time delay
% 
% Output:
%     wpe: weighted permutation entropy
%     wpe_2: normalized weighted permutation entropy in log2
%     wpe_norm: normalized weigthed permutation entropy
%     JSD: Jensen-Shannon Divergence (disequilibrium)
%     Comp_JS: MPR complexity 
%
% This code is inspired from the permutation_entropy_w_fast.m of 
% Walter Legnani's student
% =========================================================================

% Ensure data is a column vector
data = data(:);
len_y = length(data);
num_patterns = factorial(m);

% Genero las particiones
tmp = zeros(len_y, m);
for i = 1:m
    tmp(:, i) = circshift(data, [(i-1)*t, 0]);
end
partition = tmp(t*m:end, :)';

% Handle NaNs: Remove any embedding vector containing a NaN
valid_cols = ~any(isnan(partition), 1);
partition = partition(:, valid_cols);

if isempty(partition) || size(partition, 2) < num_patterns
    % Return NaNs if too many missing values are present
    wpe = NaN; wpe_2 = NaN; wpe_norm = NaN; JSD = NaN; Comp_JS = NaN;
    return;
end

% Calculo los pesos
xm = mean(partition);
weight = mean((partition - xm).^2);

% Obtengo las permutaciones
[~, permutation] = sort(partition);
idx = hash(permutation);

% Suma de los pesos para cada una de las permutaciones
count = zeros(1, num_patterns);
for i = 1:num_patterns
    count(i) = sum(weight(idx == i));
end

% Probabilty distribution
total_weight = sum(count);
if total_weight == 0
    wpe = NaN; wpe_2 = NaN; wpe_norm = NaN; JSD = NaN; Comp_JS = NaN;
    return;
end

p = count / total_weight;
p_pos = p(p > 0);

% WPE
wpe = -sum(p_pos .* log(p_pos));
wpe_2 = -sum(p_pos .* log2(p_pos)) / log2(num_patterns);
wpe_norm = -sum(p_pos .* log(p_pos)) / log(num_patterns);

% Jensen-Shannon Divergence (JSD) 
u = 1 / num_patterns; % Uniform baseline 1/m!

% H((P + U) / 2) on all m! states
p_mix = 0.5 * p + 0.5 * u;
H_mix = -sum(p_mix .* log(p_mix));

% H(P) and H(U)
H_p = -sum(p_pos .* log(p_pos));
H_u = log(num_patterns);

% JSD
JSD = H_mix - 0.5 * H_p - 0.5 * H_u;

% MPR Complexity (Comp_JS)
c1 = (0.5 + ((1 - 0.5) / num_patterns)) * log(0.5 + ((1 - 0.5) / num_patterns));
c2 = ((1 - 0.5) / num_patterns) * log((1 - 0.5) / num_patterns) * (num_patterns - 1);
c3 = 0.5 * log(num_patterns);
Q_0 = -1 / (c1 + c2 + c3);

% MPR complexity with normalized wpes
Comp_JS = Q_0 * JSD * wpe_norm;

end

% Lehmer code
function i = hash(x)
    [len, n] = size(x);
    if len == 1
        i = ones(1, n);
        return;
    end
    i = sum(x < x(1, :)) * factorial(len - 1) + hash(x(2:end, :));
end