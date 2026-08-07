function [pe pe2 pe2_normalized] = permentropy_opti(y,m,t)
% =================================================================
% Sistemas Lineales, no Lineales: Caos y Fractales 
% Doctorado en Ingenier�a
% Facultad Regional Buenos Aires - Universidad Tecnologica Nacional
% Catedra Dr. Walter Legnani
% =======================================================================
% Calculo de la entropia de permutacion y del histograma correspondiente
% Segun el metodo de Bandt y Pompe (2002)
%=========================================================================
%
%  Input:   y: time series;
%           m: orden de la entropia de permuacion
%           t: tiempo de retraso para el calculo de la entr. de permut. 
%
%  Output: 
%           pe:    entropia de permutacion usando log en base natural
%           pe2:   entropia de permutacion usando log en base 2
%           pe2_normalized: entr. de permut. usando log en base 2 y
%           normalizando
%           hist:  histograma experimental de Band y Pompe
% Por ejemplo
%               x= [4,7,9,10,6,11,3]
%               [e e2 e2_normalized hist] = permentropy(x,3,1)
%%=========================================================================

ly = length(y);
nV = ly - t*(m-1); % Number of vectors 

% Building the vectors (instead of the j loop)
offsets = (0:t:t*(m-1))';   % m x 1
starts  = 1:nV;               % 1 x ly
idx = offsets + starts;      % m x ly (autonomous broadcasting)
Y = y(idx);                  % each column is a vector to study

% Computing ordinal order
[~, IV] = sort(Y,1);
IV = IV'; % N x m, a row = a permutation vector

% Optimized couting of each permutation
[~,~,ic] = unique(IV,'rows'); % ic contains the indexes of each permutation
                              % EACH TIME IT APPEARS!
c = accumarray(ic,1); %count the frequency of apparition of each index

p = c / sum(c);
pe = -sum(p .* log(p)) / log(factorial(m));
pe2 = -sum(p .* log2(p));
pe2_normalized = -sum(p .* log2(p)) / log2(factorial(m));
