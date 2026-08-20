function [H_st,C_st] = HXC_standard_deviation(m,t,data_folder)
% =========================================================================
% From a set of (H,C) points, it displays the area fullfilled by the point
% as well as the center of the area (mean centroid) and the standard deviation
% 
% =========================================================================
% Input:
%     m: embedding dimension
%     t: embedding time delay
%     data_folder: the folder where are stored .mat (use './' for current folder)
% 
% Output:
%     Plot of the area, its center and standard-deviations bars
%     H_st: Standard deviation of Shannon entropy
%     C_st: Standard deviation of MPR Complexity
% =========================================================================

