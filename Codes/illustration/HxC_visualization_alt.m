% Entropy-Causality Plane (HC Plane) Visualization
clear; clc; close all;

% =========================================================================
% 1. PARAMETERS DEFINITION
% =========================================================================
m = 3; % Embedding dimension

% =========================================================================
% 2. COMPUTE THEORETICAL BOUNDS
% =========================================================================
[H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m);

% =========================================================================
% 3. ENTROPY-CAUSALITY PLANE VISUALIZATION
% =========================================================================
fig = figure('Position', [150, 150, 800, 600], 'Color', 'w');
hold on;

% Fill the physically accessible region (between C_min and C_max)
fill([H_max; flipud(H_min)], [C_max; flipud(C_min)], [0.9 0.9 0.9], ...
    'EdgeColor', 'none', 'DisplayName', 'Accessible Region');

% Plot theoretical boundary curves
plot(H_max, C_max, 'k-', 'LineWidth', 2, 'DisplayName', 'Upper Bound (C_{max})');
plot(H_min, C_min, 'k--', 'LineWidth', 2, 'DisplayName', 'Lower Bound (C_{min})');

% =========================================================================
% 4. DYNAMIC REGIONS ANNOTATIONS
% =========================================================================
% Random / Noise region
text(0.9, 0.05, 'Random / Stochastic', 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0 0.5 0], 'BackgroundColor', 'w', 'Margin', 2);

% Chaotic region
text(0.65, max(C_max) - 0.05, 'Chaotic', 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0.8 0.1 0.1], 'BackgroundColor', 'w', 'Margin', 2);

% Deterministic / Periodic region
text(0.15, 0.05, 'Deterministic / Periodic', 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Color', [0 0 0.5], 'BackgroundColor', 'w', 'Margin', 2);

% =========================================================================
% 5. FIGURE FORMATTING
% =========================================================================
title(sprintf('Entropy-Causality Plane (m = %d)', m), 'FontSize', 16, 'FontWeight', 'bold');
xlabel('Normalized Permutation Entropy H', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Statistical Complexity C', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0 1]);
ylim([0 max(C_max) + 0.1]);
grid on; set(gca, 'GridLineStyle', ':', 'FontSize', 12);
legend('Location', 'NorthWest', 'FontSize', 11);
box on;

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================
%% Helper Function: Compute Theoretical Curves
function [H_max, C_max, H_min, C_min] = compute_theoretical_bounds(m)
    dim = factorial(m);
    num_points = 2000; % High resolution for smooth curves
    
    % Unified fine grid for Entropy H
    H_grid = linspace(0, 1, num_points)';
    C_max_all = zeros(num_points, dim - 1);
    
    % --- Upper bound curves (C_max) ---
    for k = 1:(dim - 1)
        p_vals = linspace(0, 1, num_points)';
        P_k = zeros(num_points, dim);
        P_k(:, 1:k) = repmat((1 - p_vals) / k, 1, k);
        P_k(:, k+1) = p_vals;
        
        [H_k, C_k] = HXC_from_prob_vectorized(P_k);
        
        % Clean duplicates for monotonic interpolation
        [H_k_unique, unique_idx] = unique(H_k);
        C_k_unique = C_k(unique_idx);
        
        % Interpolate onto unified grid
        C_max_all(:, k) = interp1(H_k_unique, C_k_unique, H_grid, 'pchip', 0);
    end
    
    % Take the pointwise maximum across all generated k-curves
    H_max = H_grid;
    C_max = max(C_max_all, [], 2);
    
    % --- Lower bound curve (C_min) ---
    p_vals_min = linspace(1/dim, 1, num_points)';
    P_min = zeros(num_points, dim);
    P_min(:, 1) = p_vals_min;
    P_min(:, 2:dim) = repmat((1 - p_vals_min) / (dim - 1), 1, dim - 1);
    
    [H_min_raw, C_min_raw] = HXC_from_prob_vectorized(P_min);
    
    [H_min_unique, unique_idx] = unique(H_min_raw);
    C_min_unique = C_min_raw(unique_idx);
    
    H_min = H_grid;
    C_min = interp1(H_min_unique, C_min_unique, H_grid, 'pchip', 0);
end

%% Helper Function: Compute Normalized Entropy and Complexity
function [H, C] = HXC_from_prob_vectorized(P)
    [~, dim] = size(P);
    
    % Avoid log(0) numerical issues
    P_safe = max(P, eps);
    
    % 1. Normalized Shannon Entropy (H)
    S = -sum(P_safe .* log(P_safe), 2);
    S_max = log(dim);
    H = S / S_max;
    
    % 2. Jensen-Shannon Divergence
    U = ones(1, dim) / dim;
    P_plus_U_half = (P + U) / 2;
    S_P_plus_U = -sum(P_plus_U_half .* log(P_plus_U_half), 2);
    S_U = log(dim);
    JS = S_P_plus_U - S / 2 - S_U / 2;
    
    % 3. Normalization constant Q0
    P_delta = zeros(1, dim); P_delta(1) = 1;
    P_delta_plus_U_half = (P_delta + U) / 2;
    S_delta_plus_U = -sum(P_delta_plus_U_half .* log(P_delta_plus_U_half));
    JS_max = S_delta_plus_U - 0 / 2 - S_U / 2;
    Q0 = 1 / JS_max;
    
    % 4. Statistical Complexity (C)
    C = Q0 * JS .* H;
end