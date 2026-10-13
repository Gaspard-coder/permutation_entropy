clear;
clc;

% Archivo FIG
archivo_fig = '/home/gaspichou/Documents/git/permutation_entropy/DBT2_article/figures/kmeans_ex.fig';


% Archivo PDF
archivo_pdf = '/home/gaspichou/Documents/git/permutation_entropy/DBT2_article/figures/kmeans_ex.pdf';

% Abrir figura
h = openfig(archivo_fig, 'invisible');

% Configuración de página
set(h, 'PaperUnits', 'centimeters');
set(h, 'PaperSize', [29.7 21]);          % A4 horizontal
set(h, 'PaperPosition', [0.3 0.3 29.1 20.4]);

% Imprimir directamente a PDF
print(h, archivo_pdf, '-dpdf','-r600');

% Cerrar
close(h);

fprintf('PDF generado correctamente: %s\n', archivo_pdf);