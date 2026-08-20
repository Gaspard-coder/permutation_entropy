function [H_std,C_std] = HXC_standard_deviation(m,t,data_folder)
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
%     H_std: Standard deviation of Shannon entropy
%     C_std: Standard deviation of MPR Complexity
% =========================================================================

% Get a list of all .mat files
    file_pattern = fullfile(data_folder, '*.mat');
    file_list = dir(file_pattern);
    num_files = length(file_list);

    if num_files == 0
        error('No .mat files found in the specified directory: %s', data_folder);
    end

    H_values = zeros(num_files, 1);
    C_values = zeros(num_files, 1);

    fprintf('Processing %d files for m=%d, t=%d...\n', num_files, m, t);
    
    valid_count = 0;

    % Process each file to extract H and C
    for k = 1:num_files
        % Extract filename and full path 
        filename = file_list(k).name;
        file_path = fullfile(data_folder, filename);
        
        % Load the data from the .mat file using struct2cell to extract 
        % the first variable without knowing its name
        loaded_data = load(file_path);
        data_cells = struct2cell(loaded_data);
        
        if isempty(data_cells)
            warning('File %s is empty. Skipping.', filename);
            continue;
        end
        
        % Ensure data is a 1D column vector 
        time_series = data_cells{1}(:); 
        
        % Compute Entropy and Complexity
        [pe, ~, Comp_JS] = HXC_1_opti(time_series, m, t);
        
        valid_count = valid_count + 1;
        H_values(valid_count) = pe;
        C_values(valid_count) = Comp_JS;
    end
    
    % Truncate arrays if some files were skipped
    H_values = H_values(1:valid_count);
    C_values = C_values(1:valid_count);

    %Calculate Centroid and Standard Deviations
    H_mean = mean(H_values);
    C_mean = mean(C_values);
    H_std = std(H_values);
    C_std = std(C_values);
    
    fprintf('Centroid: H = %.4f | C = %.4f\n', H_mean, C_mean);
    fprintf('Std Dev :  H_std = %.4f | C_std = %.4f\n',  H_std, C_std);

    %Compute Theoretical Bounds for the specific m
    [H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m);

    % 5. Plotting Setup
    [~, folder_name] = fileparts(data_folder);
    folder_name = string(data_folder);
    folder_name = extractAfter(folder_name, max(strfind(folder_name, filesep))); % Extract folder name for title 
    
    figure('Name', 'Complexity-Entropy Plane: Distribution and Std Dev', ...
           'Color', 'w', 'Position', [100, 100, 850, 650]);
    hold on; grid on;

    % A. Plot theoretical bounds 
    h_cmax = plot(H_max, C_max, 'k-', 'LineWidth', 2, 'DisplayName', sprintf('C_{max} (m=%d)', m));
    h_cmin = plot(H_min, C_min, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('C_{min} (m=%d)', m));

    % B. Plot the area (all individual points in light blue)
    h_area = scatter(H_values, C_values, 40, [0.4 0.7 0.9], 'filled', ...
        'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none', ...
        'DisplayName', 'Individual Signals');

    % C. Plot the centroid and Standard Deviation error bars
    % Using errorbar to show  H_std and C_std as a crosshair
     h_std = errorbar(H_mean, C_mean, C_std, C_std, H_std, H_std, 'o', ...
        'MarkerSize', 8, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', ...
        'Color', 'k', 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Centroid \\pm 1 StdDev\n(H_{st}=%.3f, C_{st}=%.3f)', H_std, C_std));

    % D. Formatting 
    xlabel('Normalized Permutation Entropy (H)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Jensen-Shannon Complexity (C)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Distribution and Standard Deviation - %s (m=%d, t=%d)', folder_name, m, t), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    xlim([0 1]);
    ylim([0 max([max(C_max), max(C_values)]) * 1.15]); 
    legend([h_cmax; h_cmin; h_area; h_std], 'Location', 'northeastoutside');
    hold off;
end

%% Helper Function: Compute Theoretical Curves 
function [H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m)
    dim = factorial(m);
    num_points = 500; % Resolution per segment
    
    % --- Upper bound curve (C_max) ---
    P_max = zeros((dim - 1) * num_points, dim);
    for k = 1:(dim - 1)
        p_vals = linspace(1/(k+1), 1/k, num_points)';
        
        idx_start = (k - 1) * num_points + 1;
        idx_end   = k * num_points;
        
        P_max(idx_start:idx_end, 1:k) = repmat((1 - p_vals) / k, 1, k);
        P_max(idx_start:idx_end, k+1) = p_vals;
    end
    [H_max, C_max] = HXC_from_prob_vectorized(P_max);

    [H_max, sort_idx] = sort(H_max);
    C_max = C_max(sort_idx);

    % --- Lower bound curve (C_min) ---
    p_vals_min = linspace(1/dim, 1, num_points)';
    P_min = zeros(num_points, dim);
    P_min(:, 1) = p_vals_min;
    P_min(:, 2:dim) = repmat((1 - p_vals_min) / (dim - 1), 1, dim - 1);
    
    [H_min, C_min] = HXC_from_prob_vectorized(P_min);
end

%% Helper Function: Compute H and C from Probability Matrix (Vectorized) 
function [H_perm, Comp_JS] = HXC_from_prob_vectorized(P)
    dim = size(P, 2);
    entropy_max = log(dim);
    
    P_safe = P;
    P_safe(P_safe == 0) = 1;
    H_p = -sum(P .* log(P_safe), 2);
    H_perm = H_p / entropy_max;
    
    Pe = ones(1, dim) / dim;
    H_pe = log(dim);
    
    M = 0.5 * (P + repmat(Pe, size(P, 1), 1));
    M_safe = M;
    M_safe(M_safe == 0) = 1;
    H_m = -sum(M .* log(M_safe), 2);
    
    JSD = H_m - 0.5 * H_p - 0.5 * H_pe;
    
    c1 = (0.5 + ((1 - 0.5)/dim)) * log(0.5 + ((1 - 0.5)/dim));
    c2 = ((1 - 0.5)/dim) * log((1 - 0.5)/dim) * (dim - 1);
    c3 = 0.5 * log(dim);
    Q0 = -1 / (c1 + c2 + c3);
    
    Comp_JS = Q0 * JSD .* H_perm;
end