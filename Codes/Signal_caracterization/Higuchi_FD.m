function [FD] = Higuchi_FD(k_max,signal)

% =======
% This function returns the fractal dimension of a given 1D signal
% for different timescales of the k_max
% =======
% Input:
%     k_max: the maximum timescale to be tried
%     signal: .mat file to be computed
% 
% Output:
%     FD: the fractal dimension calculated accord to Higuchi's algorithm
% 
% This code was inspired by the work of Salai Selvam v 
% Salai Selvam V (2026). COMPLETE HIGUCHI FRACTAL DIMENSION ALGORITHM 
% (https://www.mathworks.com/matlabcentral/fileexchange/30119-complete-higuchi-fractal-dimension-algorithm), 
% MATLAB Central File Exchange. Retrieved August 25, 2026. 
% =======

% Loading the .mat file
if ischar(signal) || isstring(signal)
    loadedData = load(signal);
    fields = fieldnames(loadedData);
    signal = loadedData.(fields{1}); % Extracts the first variable stored in the .mat file
end

signal = signal(:)';
N = length(signal);

k_array = 1:k_max;
Lk = zeros(1, k_max);

for k = 1:k_max
    Lmk = zeros(1, k);
    
    for m = 1:k
        n_max = fix((N - m) / k);
        
        if n_max > 0
            % Subsample signal at step size k starting at m
            sub_series = signal(m : k : m + n_max * k);
            
            % Absolute difference sum across adjacent samples
            Lmki = sum(abs(diff(sub_series)));
            
            % Normalization factor
            Ng = (N - 1) / (n_max * k);
            
            % Scale-adjusted curve length for starting phase m
            Lmk(m) = (Lmki * Ng) / k;
        end
    end
    
    % Mean length for the current timescale k
    Lk(k) = mean(Lmk);
end

% Fit log(L(k)) vs log(1/k) to extract slope (Fractal Dimension)
lnk = log(1 ./ k_array);
lnLk = log(Lk);

b = polyfit(lnk, lnLk, 1);
FD = b(1);

end