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
r_array= zeros(length(t_array)*length(m_array),6);

for t= t_array
    for m= m_array
        tic
        temp = zeros(1:3);
        [pe pe2 pe2_normalized] = permentropy(S,m,t);
        r_array(t*m,6)= toc; % t_compute
        r_array(t*m,1)= t;
        r_array(t*m,2)= m;
        r_array(t*m,3)= pe;
        r_array(t*m,4)= pe2;
        r_array(t*m,5)= pe2_normalized;
    end
end

        

