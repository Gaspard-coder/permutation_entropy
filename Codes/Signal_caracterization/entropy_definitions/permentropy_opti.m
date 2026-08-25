function [pe, pe2, pe2_normalized, hist_bp] = permentropy_opti(y,m,t)
% =================================================================
% Sistemas Lineales, no Lineales: Caos y Fractales 
% Doctorado en Ingenieria
% Facultad Regional Buenos Aires - Universidad Tecnologica Nacional
% Catedra Dr. Walter Legnani
% Computation optimization by Gaspard Vibert
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
%           hist_bp:  histograma experimental de Band y Pompe
%=========================================================================

% Ensure data is a column vector for consistency
y = y(:); 

ly = length(y);
nV = ly - t*(m-1); % Number of vectors 

% Building the vectors (instead of the j loop)
offsets = (0:t:t*(m-1))';    % m x 1
starts  = 1:nV;              % 1 x nV
idx = offsets + starts;      % m x nV
Y = y(idx);                  % each column is a vector to study

% Computing ordinal order
[~, IV] = sort(Y,1);
IV = IV'; % nV x m, a row = a permutation vector


% Generate all possible m! permutations to include zeros
% MATLAB's sort() returns 1-based indices, so we use 1:m
all_patterns = perms(1:m); 
num_patterns = factorial(m);

% Match the observed patterns against the full theoretical set
[~, pattern_idx] = ismember(IV, all_patterns, 'rows');

%==========================================
% NB: to have a smaller computing time, you can use wisely the "unique" function
% but it will not consider the pattern that appear zero times (ghost pattern for
% too short signal) and you will have an incorrect probability distribution
% So the alternativ is just:
% IV = IV'; % N x m, a row = a permutation vector
% [~,~,ic] = unique(IV,'rows'); % ic contains the indexes of each permutation
%                               EACH TIME IT APPEARS!
% c = accumarray(ic,1); %count the frequency of apparition of each index
%==========================================

% Count frequencies, forcing the output array to be size m! x 1
c = accumarray(pattern_idx, 1, [num_patterns, 1]); 

% Complete probability distribution (including zeros)
p = c / sum(c);
hist_bp = p; % Experimental histogram now correctly sized at m!

% 
% Filter out zero probabilities only for the log calculation to avoid NaN
p_pos = p(p > 0);

pe = -sum(p_pos .* log(p_pos)) / log(num_patterns);
pe2 = -sum(p_pos .* log2(p_pos));
pe2_normalized = pe2 / log2(num_patterns);

end