% =========================================================================
%  Calculo de la entropia de permutacion ponderada
%  Centro de Procesamiento de Señales e Imágenes
% Input
%           y: serie temporal;
%           m: orden de la entropia de permutacion
%           t: tiempo de delay de la entropia de permutacion 
%
% Output 
%           pe:    entropia de permuacion
%           pe_2:  permutation entropy in log2
%           pe_norm: normalized permutation entropy in ln
%           hist:  histograma para el orden de la distribucion
%
% Referencias
% Ref: G Ouyang, J Li, X Liu, X Li, Dynamic Characteristics of Absence EEG Recordings with Multiscale Permutation %                             
% Entropy Analysis, Epilepsy Research, doi: 10.1016/j.eplepsyres.2012.11.003
% X Li, G Ouyang, D Richards, Predictability analysis of absence seizures with permutation entropy,     
% EpilepsyResearch,  Vol. 77pp. 70-74, 2007
%
% Agregado peso
% =========================================================================

function [pe pe_2 pe_norm] = permutation_entropy_w_fast(y,m,t)
len_y = length(y);

% Genero las particiones
tmp = zeros(len_y, m);
for i=1:m
    tmp(:, i) = circshift(y', [(i-1)*t, 0]);
end
partition = tmp(t*m:end, :)';

% Calculo los pesos
xm = mean(partition);
weight = mean((partition - xm).^2);

% Obtengo las permutaciones
[~, permutation] = sort(partition);
idx = hash(permutation);

% Suma de los pesos para cada una de las permutaciones
count = zeros(1, factorial(m));
for i = 1:factorial(m)
    count(i) = sum(weight(idx == i));
end

p = count(count~=0) / sum(count);
pe = -sum(p.*log(p));
pe_2 = -sum(p.*log2(p)) / log2(factorial(m)); %normalizada, log base 2
pe_norm = -sum(p.*log(p)) / log(factorial(m)); %normalized, ln
end
% Lehmer code
function i = hash(x)
    % Devuelve un vector de indices de acuerdo a la permutacion (colwise):
    % Ej:
    %   3   3   2   2   1   1
    %   2   1   3   1   3   2
    %   1   2   1   3   2   3
    %   ---------------------
    %   6   5   4   3   2   1
    [len, n] = size(x);
    
    if len == 1
        i = ones(1, n);
        return;
    end
    
    i = sum(x < x(1, :)) * factorial(len - 1) + hash(x(2:end, :));
end
