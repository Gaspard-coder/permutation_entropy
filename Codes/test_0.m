clc; clear; close all;
% s= [4,7,9,10,6,11,3];
% [e,e2,e2_normalizada] = permentropy(s,3,1);

data= load('x_sin.mat');
fields= fieldnames(data);
S = data.(fields{1});
tic;
[pe pe2 pe2_normalizada] = permentropy(S,5,1)
T_end = toc
