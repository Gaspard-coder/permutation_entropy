function [H_mean1, C_mean1, H_mean2, C_mean2, H_std1, C_std1, H_std2, C_std2] = WHXC_standard_deviation_compare(m, t, data_folder1, data_folder2)
% =========================================================================
% Compares two sets of signals on the Complexity-Entropy plane.
% 
% Input:
%     m: embedding dimension
%     t: embedding time delay
%     data_folder1: path to the first folder with .mat files
%     data_folder2: path to the second folder with .mat files
% 
% Output:
%     Plot comparing the two areas, their centroids, and std deviation bars.
%     H_std1, C_std1: Std deviation for Folder 1
%     H_std2, C_std2: Std deviation for Folder 2
% =========================================================================

    % Process both folders
    fprintf('\n--- Processing Source 1 ---\n');
    [H_vals1, C_vals1, H_mean1, C_mean1, H_std1, C_std1, name1] = process_folder(data_folder1, m, t);
    
    fprintf('\n--- Processing Source 2 ---\n');
    [H_vals2, C_vals2, H_mean2, C_mean2, H_std2, C_std2, name2] = process_folder(data_folder2, m, t);

    % Compute Theoretical Bounds for the specific m
    [H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m);

    % 3. Plotting Setup
    figure('Name', 'Complexity-Weigthed Entropy Plane: Comparison', ...
           'Color', 'w', 'Position', [100, 100, 950, 700]);
    hold on; grid on;

    % A. Plot theoretical bounds 
    h_cmax = plot(H_max, C_max, 'k-', 'LineWidth', 2, 'DisplayName', sprintf('C_{max} (m=%d)', m));
    h_cmin = plot(H_min, C_min, 'k--', 'LineWidth', 2, 'DisplayName', sprintf('C_{min} (m=%d)', m));

    % B. Plot the area for Folder 1 (Light Blue [0.4 0.7 0.9])
    h_area1 = scatter(H_vals1, C_vals1, 40, 'blue' , 'filled', ...
        'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none', ...
        'DisplayName', sprintf('Signals: %s', name1));

    % C. Plot the area for Folder 2 (Light Coral/Red [0.9 0.5 0.5])
    h_area2 = scatter(H_vals2, C_vals2, 40, 'red' , 'filled', ...
        'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none', ...
        'DisplayName', sprintf('Signals: %s', name2));

    % D. Plot the centroid and Std Dev for Folder 1 (Blue marker)
    h_std1 = errorbar(H_mean1, C_mean1, C_std1, C_std1, H_std1, H_std1, 'o', ...
        'MarkerSize', 8, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0 0.45 0.74], ...
        'Color', [0 0.45 0.74], 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Centroid 1 (%s)\nH_{st}=%.3f, C_{st}=%.3f', name1, H_std1, C_std1));

    % E. Plot the centroid and Std Dev for Folder 2 (Red marker)
    h_std2 = errorbar(H_mean2, C_mean2, C_std2, C_std2, H_std2, H_std2, 'o', ...
        'MarkerSize', 8, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0.85 0.33 0.1], ...
        'Color', [0.85 0.33 0.1], 'LineWidth', 1.5, ...
        'DisplayName', sprintf('Centroid 2 (%s)\nH_{st}=%.3f, C_{st}=%.3f', name2, H_std2, C_std2));

    % F. Formatting 
    xlabel('Normalized Weigthed Permutation Entropy (H)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Jensen-Shannon Complexity (C)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Comparison: %s vs %s (m=%d, t=%d)', name1, name2, m, t), ...
        'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    xlim([0 1]);
    max_c = max([C_max(:); C_vals1(:); C_vals2(:)]);
    ylim([0 max_c * 1.15]); 
    legend([h_cmax; h_cmin; h_area1; h_area2; h_std1; h_std2], 'Location', 'northeastoutside', 'Interpreter', 'none');
    hold off;
end

%% Helper Function: Process a single folder
function [H_vals, C_vals, H_mean, C_mean, H_std, C_std, folder_label] = process_folder(data_folder, m, t)
    file_pattern = fullfile(data_folder, '*.mat');
    file_list = dir(file_pattern);
    num_files = length(file_list);
    
    if num_files == 0
        error('No .mat files found in the directory: %s', data_folder);
    end
    
    H_temp = zeros(num_files, 1);
    C_temp = zeros(num_files, 1);
    fprintf('Processing %d files for m=%d, t=%d in %s...\n', num_files, m, t, data_folder);
    
    valid_count = 0;
    for k = 1:num_files
        filename = file_list(k).name;
        file_path = fullfile(data_folder, filename);
        
        loaded_data = load(file_path);
        data_cells = struct2cell(loaded_data);
        
        if isempty(data_cells)
            warning('File %s is empty. Skipping.', filename);
            continue;
        end
        
        time_series = data_cells{1}(:); 
        [~, ~, wpe_norm,~, Comp_JS] = WHXC(time_series, m, t);
        
        valid_count = valid_count + 1;
        H_temp(valid_count) = wpe_norm;
        C_temp(valid_count) = Comp_JS;
    end
    
    H_vals = H_temp(1:valid_count);
    C_vals = C_temp(1:valid_count);
    
    H_mean = mean(H_vals);
    C_mean = mean(C_vals);
    H_std = std(H_vals);
    C_std = std(C_vals);
    
    fprintf('-> Centroid: H = %.4f | C = %.4f\n', H_mean, C_mean);
    fprintf('-> Std Dev : H = %.4f | C = %.4f\n', H_std, C_std);
    
    % Safe folder name extraction
    [~, folder_label] = fileparts(data_folder);
    if isempty(folder_label) || folder_label == "."
        folder_split = strsplit(data_folder, filesep);
        folder_label = folder_split{max(1, end-1)};
    end
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
