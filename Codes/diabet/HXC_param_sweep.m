function HXC_param_sweep(t_array, m_array, folder1, folder2)
% =========================================================================
% This function performs a 2D parameter sweep over embedding dimensions (m) 
% and time embedding delays (t) to optimize class separation in the 
% Complexity-Entropy (H x C) plane.
% 
% Outputs both a 2D heatmap and multi-line curves showing the distance 
% separation vs m for each fixed t value.
%
% =========================================================================
% Input:
%     t_array     : vector of time embedding delays to test
%     m_array     : vector of embedding dimensions to test
%     folder1     : path to folder containing class 1 .mat files
%     folder2     : path to folder containing class 2 .mat files
% 
% Output:
%     best_m      : optimal embedding dimension
%     best_t      : optimal time delay yielding maximum centroid separation
%     best_dist   : maximum Euclidean distance between folder centroids
%     Plots       : Heatmap + Distance vs m curves for each t
% =========================================================================

dist = zeros(length(m_array), length(t_array));

for idx_m = 1:length(m_array)
    m = m_array(idx_m);
    for idx_t = 1:length(t_array)
        t = t_array(idx_t);
        
        [~, ~, H_mean1, C_mean1] = process_folder(folder1, m, t);
        [~, ~, H_mean2, C_mean2] = process_folder(folder2, m, t);
        
        % Distance between the centroids (H_mean, C_mean)
        dist(idx_m, idx_t) = pdist2([H_mean1, C_mean1], [H_mean2, C_mean2]);
    end
end

% Find optimal (m, t) pair
[best_dist, max_idx] = max(dist(:));
[best_m_idx, best_t_idx] = ind2sub(size(dist), max_idx);
best_m = m_array(best_m_idx);
best_t = t_array(best_t_idx);

fprintf('\n=== Results ===\n');
fprintf('Best embedding dimension (m)   : %d\n', best_m);
fprintf('Best embedding time delay (t) : %d\n', best_t);
fprintf('Maximum distance between centroids : %.4f\n', best_dist);

% Display Figures (Side-by-side)
figure('Color', 'w', 'Position', [100, 100, 1100, 450]);

% 1. Heatmap f(m, t)
subplot(1, 2, 1);
imagesc(t_array, m_array, dist);
axis xy;
colorbar;
xlabel('Time embedding delay (t)');
ylabel('Embedding dimension (m)');
title('Distance Heatmap f(m, t)');
yticks(m_array);
xticks(t_array);

% 2. Distance vs m for each fixed t
subplot(1, 2, 2);
plot(m_array, dist, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Embedding dimension (m)');
ylabel('Distance between centroids');
title('Distance vs m (for each t)');
xticks(m_array);

% Generate legend dynamic labels
legend_labels = arrayfun(@(t) sprintf('t = %d', t), t_array, 'UniformOutput', false);
legend(legend_labels, 'Location', 'bestoutside');

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
        [pe, ~, Comp_JS] = HXC_1_opti(time_series, m, t);
        
        valid_count = valid_count + 1;
        H_temp(valid_count) = pe;
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