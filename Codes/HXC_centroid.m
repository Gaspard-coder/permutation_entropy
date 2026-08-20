function HXC_centroid(m_array,t_array, data_folder)
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

coordinates = zeros(num_files, 2); % (H,C) matrix for each point
centroids = zeros(length(m_array)*length(t_array),4); % (m,t,H,C) matrix for each (m,t) set

fprintf('Processing %d files...\n', num_files);

row = 0;
for m = m_array
    for t = t_array
        row = row + 1;
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
        
            coordinates(k, :) = [H_values(k), C_values(k)]
        end
        A = mean(coordinates)
        centroids(row,:) = [m, t, A]
    end
end
%Plotting
    figure('Name', 'Complexity-Entropy Plane with centroids for a given (m,t)', ...
           'Color', 'w', 'Position', [100, 100, 850, 650]);
    hold on; grid on;

    % Plot empirical data points
    colors = lines(length(m_array)*length(t_array));
    data_handles = zeros(length(m_array)*length(t_array), 1);
    clean_names = cellfun(@(x) strrep(x, '.mat', ''), file_names, 'UniformOutput', false);

    for k = 1:num_files
        data_handles(k) = scatter(centroids(k,3), centroids(k,4), 120, ...
            'Marker', 'x', ...
            'MarkerEdgeColor', colors(k,:), ...
            'LineWidth', 2, ...
            'DisplayName', clean_names{k});
    end

