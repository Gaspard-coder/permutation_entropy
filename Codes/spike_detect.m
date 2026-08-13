function [pe] = spike_detect(y, m_array, t_array, w_size, slid)
% SPIKE_DETECT Calculates Weighted-Permutation Entropy (WPE) over a moving 
% window to detect transient spikes or sharp signal changes.
%
% Inputs:
%   y       : 1D time series signal vector
%   m_array : Scalar or vector of embedding dimensions (m)
%   t_array : Scalar or vector of time delays (tau)
%   w_size  : Moving window size in samples
%   slid    : Step size / shift between consecutive windows in samples
%
% Output:
%   pe      - Calculated WPE values across sliding windows
%             (Size: [num_m, num_t, num_windows] or [1, num_windows] if scalar parameters)

    % Ensure signal is a row vector
    y = y(:)'; 
    len_y = length(y);
    
    % Parameter validation
    max_embedding = max(m_array) * max(t_array);
    if w_size <= max_embedding
        error('w_size must be strictly greater than max(m_array) * max(t_array).');
    end
    
    % Calculate total number of sliding windows
    n_windows = floor((len_y - w_size) / slid) + 1;
    if n_windows < 1
        error('Window size w_size exceeds the total signal length.');
    end
    
    num_m = length(m_array);
    num_t = length(t_array);
    
    % Preallocate output matrix
    pe = zeros(num_m, num_t, n_windows);
    win_centers = zeros(1, n_windows);
    
    % Sliding window computation
    for k = 1:n_windows
        idx_start = (k - 1) * slid + 1;
        idx_end = idx_start + w_size - 1;
        win_centers(k) = (idx_start + idx_end) / 2;
        
        sub_y = y(idx_start:idx_end);
        
        for im = 1:num_m
            m_val = m_array(im);
            for it = 1:num_t
                t_val = t_array(it);
                % Call permutation_entropy_w_fast (uses normalized log output pe)
                [~, pe_val] = permutation_entropy_w_fast(sub_y, m_val, t_val);
                pe(im, it, k) = pe_val;
            end
        end
    end
    
    % Simplify dimensions if scalar inputs were given for m and t
    if num_m == 1 && num_t == 1
        pe = squeeze(pe)';
    end

    % --- Plotting Results (Inspired by Section IV of Fadlallah et al., 2013) ---
    figure('Color', 'w');
    
    % Top subplot: Original Signal
    subplot(2, 1, 1);
    plot(1:len_y, y, 'b', 'LineWidth', 1.1);
    grid on;
    xlabel('Samples');
    ylabel('Amplitude');
    title('Input Time Series Signal');
    xlim([1, len_y]);
    
    % Bottom subplot: Moving Window WPE
    subplot(2, 1, 2);
    hold on;
    if num_m == 1 && num_t == 1
        plot(win_centers, pe, 'r-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('WPE (m=%d, \\tau=%d)', m_array(1), t_array(1)));
    else
        for im = 1:num_m
            for it = 1:num_t
                curve = squeeze(pe(im, it, :));
                plot(win_centers, curve, 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('WPE (m=%d, \\tau=%d)', m_array(im), t_array(it)));
            end
        end
    end
    hold off;
    grid on;
    xlabel('Window Center (Samples)');
    ylabel('Normalized WPE');
    title('Weighted-Permutation Entropy Trajectory');
    legend('show', 'Location', 'best');
    xlim([1, len_y]);
    
    % Synchronize horizontal axes for interactive zooming
    linkaxes(findall(gcf, 'type', 'axes'), 'x');
end


