function [r_array] = param_computing(file,m_array,t_array)
% =================================
% Computing the influence of embedding dimension m
% and embedding time delay t
% =================================
% Input : file: .mat signal to compute
%         m_array: embedding dimension array to test
%         t_array: embedding time delay array to test
%  Output: 
%           r_array: the resut array with [m, t, pe, pe2, pe2_normalized, t_compute]
%           for every (m,t) combinaison
%  Example:
%  param_computing('x_rand.mat',5,1)
% =================================

data= load(file);
fields= fieldnames(data);
S = data.(fields{1});
nT = length(t_array);
nM = length(m_array);
r_array = zeros(nT*nM, 6);
 
row = 0;
for t = t_array
    for m = m_array
        row = row + 1;
        tic;
        [pe, pe2, pe2_normalized] = permentropy(S,m,t);
        t_compute = toc;
 
        r_array(row,1) = t;
        r_array(row,2) = m;
        r_array(row,3) = pe;
        r_array(row,4) = pe2;
        r_array(row,5) = pe2_normalized;
        r_array(row,6) = t_compute;
    end
end


        

