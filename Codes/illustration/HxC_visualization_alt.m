function HxC_visualization_alt()
% Script optimisé pour le plan Causal Entropy-Complexity (H x C)
m = 6; % Dimension d'encastrement (m = 3, 4, 5 ou 6)

% 1. Calcul ultra-rapide des bornes théoriques (faible consommation RAM)
[H_max, C_max, H_min, C_min] = compute_theoretical_bounds_fast(m);

% Création de la figure
fig = figure('Name', 'HxC Causal Plane', 'Color', 'w', 'Position', [150 150 950 600]);
hold on;

% Fonction anonyme pour interpoler la limite supérieure (C_max)
getCMax = @(h_vals) interp1(H_max, C_max, h_vals, 'pchip');

% =========================================================================
% 2. Courbe fBm (Orange / Jaune) & Fonction d'interpolation (Plancher)
% =========================================================================
h_fbm = linspace(0.37, 0.98, 100);
c_fbm = pchip([0.37,0.42, 0.65, 0.85, 0.98], [0.25,0.28, 0.33, 0.25, 0.06], h_fbm);

% Fonction anonyme d'interpolation de la courbe fBm (renvoie 0 hors domaine)
getCFbm = @(h_vals) interp1(h_fbm, c_fbm, h_vals, 'pchip', 0);

% =========================================================================
% 3. Tracé des régions colorées (Strictement au-dessus de fBm)
% =========================================================================

% Zone 2 (Rose clair) - Fond principal (s'appuie sur fBm)
h2 = linspace(0.32, 0.88, 150);
c2_top = getCMax(h2) - 0.001;
c2_bot_raw = pchip([0.32, 0.42, 0.65, 0.88], ...
    [0.32, getCFbm(0.42)+0.002, getCFbm(0.65)+0.002, getCFbm(0.88)+0.002], h2);
c2_bot = max(c2_bot_raw, getCFbm(h2) + 0.002);
patch([h2, fliplr(h2)], [c2_top, fliplr(c2_bot)], ...
    [1 0.78 0.96], 'EdgeColor', 'none', 'FaceAlpha', 0.6);

% Zone 1 (Violet) - Suit C_max au début, puis s'arrête sur la courbe fBm
h1 = linspace(0.00, 0.45, 150);
c1_top = pchip([0.0, 0.18, 0.32, 0.38, 0.45], ...
    [0.0, getCMax(0.18), getCMax(0.32), getCMax(0.38), 0.312], h1);
c1_bot_raw = pchip([0.0, 0.18, 0.32, 0.40, 0.45], ...
    [0.0, 0.15, 0.22, 0.27, getCFbm(0.45)+0.002], h1);
c1_bot = max(c1_bot_raw, getCFbm(h1) + 0.002);
patch([h1, fliplr(h1)], [c1_top, fliplr(c1_bot)], ...
    [0.78 0.68 1], 'EdgeColor', 'none', 'FaceAlpha', 0.65);

% Zone 3 (Cyan / Turquoise) - Forme en goutte arrondie
h3 = linspace(0.72, 1.00, 150);
c3_top = getCMax(h3) - 0.001;
c3_bot_raw = pchip([0.72, 0.78, 0.88, 0.96, 1.00], ...
    [c3_top(1), getCFbm(0.78)+0.002, getCFbm(0.88)+0.002, 0.12, 0.00], h3);
c3_bot = max(c3_bot_raw, getCFbm(h3) + 0.002);
patch([h3, fliplr(h3)], [c3_top, fliplr(c3_bot)], ...
    [0.0 0.82 0.82], 'EdgeColor', 'none', 'FaceAlpha', 0.7);

% ==========================================
% 4. Plot fBm Curve & Theoretical Boundaries
% ==========================================
% fBm line (Orange / Jaune)
plot(h_fbm, c_fbm, 'Color', [1 0.6 0], 'LineWidth', 2.5);

% Tracé des bornes théoriques
plot(H_max, C_max, 'k-', 'LineWidth', 1.0);
plot(H_min, C_min, 'k--', 'LineWidth', 1.0);

% =========================================================================
% 5. Annotations et mise en forme du graphique
% =========================================================================
% Nombres des zones
text(0.31, 0.27, '1', 'FontSize', 22, 'FontName', 'Arial');
text(0.63, 0.46, '2', 'FontSize', 22, 'FontName', 'Arial');
text(0.78, 0.36, '3', 'FontSize', 22, 'FontName', 'Arial');
text(0.87, 0.25, '4', 'FontSize', 22, 'FontName', 'Arial');

% Texte descriptif en haut à gauche
text(0.08, 0.56, {'1 - Periodic or Deterministic'}, ...
    'FontSize', 12, 'FontName', 'Arial', 'VerticalAlignment', 'top');
text(0.08, 0.50, '2 - Chaotic', ...
    'FontSize', 12, 'FontName', 'Arial', 'VerticalAlignment', 'top');
text(0.08, 0.44, {'3 - Chaotic with', '       strong noise', '       component'}, ...
    'FontSize', 12, 'FontName', 'Arial', 'VerticalAlignment', 'top');
text(0.08, 0.36, {'4 - Random'}, ...
    'FontSize', 12, 'FontName', 'Arial', 'VerticalAlignment', 'top');

% Configuration des axes
xlabel('Normalized Permutation Entropy H', 'FontSize', 15, 'FontWeight', 'bold');
ylabel('Complexity C', 'FontSize', 15, 'FontWeight', 'bold');
xlim([-0.02 1.02]);
ylim([-0.02 0.62]);
set(gca, 'XTick', 0:0.2:1.0, 'YTick', 0:0.1:0.6);

grid off; box on;
ax = gca;
ax.TickDir = 'in';
ax.XMinorTick = 'on';
ax.YMinorTick = 'on';
ax.LineWidth = 1.0;
hold off;
end

%% --- Calcul Analytique Optimisé des Bornes (Consommation RAM ~ 0 Mo) ---
function [H_max, C_max, H_min, C_min] = compute_theoretical_bounds_fast(m)
dim = factorial(m);
S_max = log(dim);

% Constante de normalisation Q0 (D_max)
P_ext_avg_1 = 0.5 * (1 + 1/dim);
P_ext_avg_rest = 0.5 * (1/dim);
S_ext_avg = - (P_ext_avg_1 * log(P_ext_avg_1) + (dim - 1) * P_ext_avg_rest * log(P_ext_avg_rest));
D_max = S_ext_avg - 0.5 * S_max;
Q0 = 1 / D_max;

num_p = 100;

% --- Upper Bound (C_max) ---
H_max_list = [];
C_max_list = [];
for k = 1:(dim - 1)
    p = linspace(1/(k+1), 1/k, num_p);
    p_other = (1 - p) / k;
    p_other_safe = max(p_other, eps);
    S = - (k * p_other_safe .* log(p_other_safe) + p .* log(p));
    H = S / S_max;

    a = 0.5 * p_other + 0.5 / dim;
    b = 0.5 * p + 0.5 / dim;
    c = 0.5 / dim;
    S_avg = - (k * a .* log(a) + b .* log(b) + (dim - 1 - k) * c .* log(c));
    D_JS = S_avg - 0.5 * S - 0.5 * S_max;
    C = Q0 * D_JS .* H;

    H_max_list = [H_max_list, H];
    C_max_list = [C_max_list, C];
end
[H_max, sort_idx] = sort(H_max_list);
C_max = C_max_list(sort_idx);

% --- Lower Bound (C_min) ---
p_min = linspace(1/dim, 1, 500);
p_other_min = (1 - p_min) / (dim - 1);
p_other_min_safe = max(p_other_min, eps);
S_min = - (p_min .* log(p_min) + (dim - 1) * p_other_min_safe .* log(p_other_min_safe));
H_min_val = S_min / S_max;

u = 0.5 * p_min + 0.5 / dim;
v = 0.5 * p_other_min + 0.5 / dim;
S_avg_min = - (u .* log(u) + (dim - 1) * v .* log(v));
D_JS_min = S_avg_min - 0.5 * S_min - 0.5 * S_max;
C_min_val = Q0 * D_JS_min .* H_min_val;

[H_min, sort_idx_min] = sort(H_min_val);
C_min = C_min_val(sort_idx_min);
end