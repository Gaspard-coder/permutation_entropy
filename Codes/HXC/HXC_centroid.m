function [centroids]=HXC_centroid(m_array,t_array, data_folder)
% =========================================================================
% The main idea is to study on the feature plan Complexity C vs Normalized
% Shannon Entropy H how behave the centroid (in the mean way) of a set 
% of signals
% =========================================================================
% Input: 
%     m_array: embedding dimension array
%     t_array: embedding time delay array
%     data_folder: the folder where are stored .mat (use './' for current folder)
% 
% Output:
%     Plot of the centroid position for a given (m,t)
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
file_names = cell(num_files, 1);

centroids = zeros(length(m_array)*length(t_array),4); % (m,t,H,C) matrix for each (m,t) set

fprintf('Processing %d files...\n', num_files);

row = 0;
for m = m_array
    for t = t_array
        row = row + 1;
        coordinates = zeros(num_files, 2); % (H,C) matrix for each point
        for k = 1:num_files
            % Extract filename and full path
            filename = file_list(k).name;
            file_names{k} = filename;
            file_path = fullfile(data_folder, filename);
            
            % Load the data from the .mat file using struct2cell to extract 
            % the first variable without knowing its name
            loaded_data = load(file_path);
            data_cells = struct2cell(loaded_data);
            
            if isempty(data_cells)
                warning('File %s is empty. Skipping.', filename);
                continue;
            end
            
            % Assuming the first variable in the .mat file is the time series
            time_series = data_cells{1}; 
            
            % Ensure data is a 1D column vector as required by HXC_1_opti
            time_series = time_series(:); 
            [pe, ~, Comp_JS] = HXC_1_opti(time_series, m, t);
            H_values(k) = pe;
            C_values(k) = Comp_JS;
            fprintf('File: %-20s | H: %.4f | C: %.4f\n', filename, pe, Comp_JS);
        
            coordinates(k, :) = [H_values(k), C_values(k)];
        end
        A = mean(coordinates);
        centroids(row,:) = [m, t, A];
    end
end
%Plotting
[~, folder_name] = fileparts(data_folder);
folder_name = string(data_folder);
folder_name = extractAfter(folder_name, max(strfind(folder_name, filesep)));
figure('Name', 'Complexity-Entropy Plane: Centroids with Theoretical Bounds', ...
           'Color', 'w', 'Position', [100, 100, 850, 650]);
    hold on; grid on;

    % theoretical bounds for each  m
    unique_m = unique(m_array);
    bound_handles = [];
    max_c_val = max(centroids(:, 4));

    for i = 1:length(unique_m)
        m_curr = unique_m(i);
        [H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m_curr);
        
        max_c_val = max([max_c_val; C_max(:)]); % Track max height for y-axis

        if length(unique_m) == 1
            h_cmax = plot(H_max, C_max, 'k-', 'LineWidth', 2, 'DisplayName', sprintf('C_{max} (m=%d)', m_curr));
            h_cmin = plot(H_min, C_min, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('C_{min} (m=%d)', m_curr));
        else
            % Line styles change if plotting multiple m dimensions
            h_cmax = plot(H_max, C_max, '--', 'LineWidth', 1.5, 'DisplayName', sprintf('C_{max} (m=%d)', m_curr));
            h_cmin = plot(H_min, C_min, ':', 'LineWidth', 1.5, 'DisplayName', sprintf('C_{min} (m=%d)', m_curr));
        end
        bound_handles = [bound_handles; h_cmax; h_cmin]; %#ok<AGROW>
    end

    % Plot centroid markers
    num_centroids = size(centroids, 1);
    colors = lines(num_centroids);
    data_handles = zeros(num_centroids, 1);

    for k = 1:num_centroids
        m_val  = centroids(k, 1);
        t_val  = centroids(k, 2);
        H_mean = centroids(k, 3);
        C_mean = centroids(k, 4);
        
        label_str = sprintf('(m=%d, t=%d)', m_val, t_val);
        
        data_handles(k) = scatter(H_mean, C_mean, 140, colors(k, :), 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5, ...
            'DisplayName', label_str);
        
        text(H_mean + 0.015, C_mean, label_str, ...
            'FontSize', 10, 'FontWeight', 'bold', 'Color', colors(k, :), ...
            'Interpreter', 'none');
    end

    % Formatting
    xlabel('Normalized Permutation Entropy (H)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Jensen-Shannon Complexity (C)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Centroid Positions on the Complexity-Entropy Plane - %s', folder_name), ...
    'FontSize', 14, 'FontWeight', 'bold');
    
    xlim([0 1]);
    ylim([0 max_c_val * 1.1]);
    legend([bound_handles; data_handles], 'Location', 'northeastoutside');
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
        
        % Block-vectorized assignment (faster)
        idx_start = (k - 1) * num_points + 1;
        idx_end   = k * num_points;
        
        P_max(idx_start:idx_end, 1:k) = repmat((1 - p_vals) / k, 1, k);
        P_max(idx_start:idx_end, k+1) = p_vals;
    end
    [H_max, C_max] = HXC_from_prob_vectorized(P_max);

    % Sort just in case, to guarantee a smooth line plot from left to right
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
    % P is a matrix of size [N_distributions x dim]
    dim = size(P, 2);
    entropy_max = log(dim);
    
    % Avoid log(0) by setting 0 values to 1 (since 1 * log(1) = 0)
    P_safe = P;
    P_safe(P_safe == 0) = 1;
    H_p = -sum(P .* log(P_safe), 2);
    H_perm = H_p / entropy_max;
    
    % Uniform distribution baseline
    Pe = ones(1, dim) / dim;
    H_pe = log(dim);
    
    % Mixture distribution
    M = 0.5 * (P + repmat(Pe, size(P, 1), 1));
    M_safe = M;
    M_safe(M_safe == 0) = 1;
    H_m = -sum(M .* log(M_safe), 2);
    
    % Jensen-Shannon Divergence
    JSD = H_m - 0.5 * H_p - 0.5 * H_pe;
    
    % Normalization constant
    c1 = (0.5 + ((1 - 0.5)/dim)) * log(0.5 + ((1 - 0.5)/dim));
    c2 = ((1 - 0.5)/dim) * log((1 - 0.5)/dim) * (dim - 1);
    c3 = 0.5 * log(dim);
    Q0 = -1 / (c1 + c2 + c3);
    
    Comp_JS = Q0 * JSD .* H_perm;
end

