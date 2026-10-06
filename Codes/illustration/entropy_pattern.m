% Permutation Entropy Pattern Identification and Visualization
clear; clc; close all;

% =========================================================================
% 1. PARAMETERS DEFINITION
% =========================================================================
% Define the input time series and permutation parameters
x = [9, 6, 4, 12, 8, 13, 5]; % Any arbitrary time series
m = 3;                        % Embedding dimension (n in the image)
tau = 1;                      % Time delay
highlight_idx = 3;            % Index of the specific window to highlight 

N = length(x);
num_vectors = N - (m - 1) * tau;

% =========================================================================
% 2. PATTERN EXTRACTION (SYMBOLIC DYNAMICS)
% =========================================================================
% Generate all possible m! permutations in lexicographical order
all_perms = perms(1:m);
all_perms = sortrows(all_perms); 
num_perms = factorial(m);

% Extract windows and calculate their rank patterns
patterns = zeros(num_vectors, m);
for i = 1:num_vectors
    % Extract the sub-sequence based on m and tau
    window_indices = i : tau : i + (m - 1) * tau;
    window_values = x(window_indices);
    
    % Determine the ordinal rank (symbolic representation)
    % A stable sort is used to assign consecutive ranks to the values
    [~, order] = sort(window_values);
    [~, rank] = sort(order);
    patterns(i, :) = rank;
end

% Calculate the frequency of each permutation pattern
counts = zeros(num_perms, 1);
for i = 1:num_perms
    % Check for matches between the current permutation and all sequence patterns
    matches = ismember(patterns, all_perms(i, :), 'rows');
    counts(i) = sum(matches);
end
freqs = counts / num_vectors;

% =========================================================================
% 3. VISUALIZATION
% =========================================================================
fig = figure('Position', [100, 100, 800, 800], 'Color', 'w');
%sgtitle('Symbolic Dynamics and Permutation Complexity', 'FontSize', 18, 'FontWeight', 'bold');

% --- SUBPLOT 1: Time Series and Highlighted Pattern ---
subplot(3, 1, 1);
plot(1:N, x, '-ks', 'MarkerFaceColor', 'k', 'MarkerSize', 8, 'LineWidth', 1.2); 
hold on;

% Highlight the specified window (green line, red squares)
h_idx = highlight_idx : tau : highlight_idx + (m - 1) * tau;
plot(h_idx, x(h_idx), '-rs', 'MarkerFaceColor', 'r', 'Color', 'g', 'LineWidth', 2, 'MarkerSize', 8);

% Annotate the highlighted pattern
highlight_pattern_str = sprintf('(%s)', join(string(patterns(highlight_idx,:)), ','));
text(h_idx(2) + 0.1, x(h_idx(2)) + 1, highlight_pattern_str, 'FontSize', 12, 'FontWeight', 'bold');

% Formatting
title(sprintf('x = [%s], m = %d, \\tau = %d', num2str(x), m, tau), 'FontSize', 14, 'FontWeight', 'bold');
ylabel('x', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('i', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0.5, N + 0.5]);
ylim([min(x)-1, max(x)+2]);
grid on; set(gca, 'GridLineStyle', ':');

% --- SUBPLOT 2: Relative Frequencies Bar Chart ---
subplot(3, 1, 2);
bar(1:num_perms, freqs, 0.5, 'FaceColor', 'k');

% Formatting Y-ticks as fractions for clarity matching the total number of vectors
max_count = max(counts) + 1;
yticks_vals = (0:max_count) / num_vectors;
ytick_labels = arrayfun(@(v) sprintf('%d/%d', v, num_vectors), 0:max_count, 'UniformOutput', false);
ytick_labels{1} = '0';

set(gca, 'YTick', yticks_vals, 'YTickLabel', ytick_labels);
ylabel({'relative frequency', 'p_i'}, 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', 1:num_perms, 'XTickLabel', []);
xlim([0.5, num_perms + 0.5]);
ylim([0, max_count / num_vectors]);
grid on; set(gca, 'GridLineStyle', ':');

% --- SUBPLOT 3: Permutation Patterns Mapping ---
subplot(3, 1, 3);
hold on;
for i = 1:num_perms
    % Generate local x-coordinates to center the shape under the corresponding bar
    x_pos = linspace(i - 0.3, i + 0.3, m);
    plot(x_pos, all_perms(i, :), '-ks', 'MarkerFaceColor', 'k', 'LineWidth', 1.5, 'MarkerSize', 6);
end

% Format X-axis labels dynamically based on generated permutations
labels = cell(1, num_perms);
for i = 1:num_perms
    labels{i} = sprintf('(%s)', join(string(all_perms(i,:)), ','));
end

set(gca, 'XTick', 1:num_perms, 'XTickLabel', labels, 'FontSize', 10, 'FontWeight', 'bold');
ylabel({'rank value', 'in sequence'}, 'FontSize', 14, 'FontWeight', 'bold');
xlabel('i^{th} permutation pattern', 'FontSize', 14, 'FontWeight', 'bold');
xlim([0.5, num_perms + 0.5]);
ylim([0.5, m + 0.5]);
set(gca, 'YTick', 1:m);
grid on; set(gca, 'GridLineStyle', ':');

% Adjust subplot layout spacing
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.6, 0.9]);
