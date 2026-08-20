t_array = 1:35;
m = 4;
folder1 = './Data_base/Atrial_fibrillation/NSR';
folder2 = './Data_base/Atrial_fibrillation/AFIB';

dist = zeros(1, length(t_array));

for idx = 1:length(t_array)
    t = t_array(idx);
    
    [~, ~, H_mean1, C_mean1] = process_folder(folder1, m, t);
    [~, ~, H_mean2, C_mean2] = process_folder(folder2, m, t);
    
    % Distance between the centroids (H_mean, C_mean)
    dist(idx) = pdist2([H_mean1, C_mean1], [H_mean2, C_mean2]);
end

[best_dist, best_idx] = max(dist);
best_t = t_array(best_idx);

fprintf('\n=== Results ===\n');
fprintf('Best embedding time delay (t) : %d\n', best_t);
fprintf('Maximum distance between centroids : %.4f\n', best_dist);

% Distance against t curve
figure('Color', 'w');
plot(t_array, dist, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
grid on;
xlabel('Time embedding delay (t)');
ylabel('Distance between centroids');
title(sprintf('Distance between the centroids depending of t (m = %d)', m));

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