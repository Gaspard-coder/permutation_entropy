function convert_csv_to_mat(folderPath)
% CONVERT_CSV_TO_MAT Convertit tous les fichiers .csv d'un dossier en .mat
%
% Usage :
%   convert_csv_to_mat()                 % Utilise le dossier courant
%   convert_csv_to_mat('C:\mon_dossier') % Utilise le dossier spécifié

if nargin < 1 || isempty(folderPath)
    folderPath = pwd;
end

% Recherche de tous les fichiers .csv
csvFiles = dir(fullfile(folderPath, '*.csv'));

if isempty(csvFiles)
    fprintf('Aucun fichier .csv trouvé dans : %s\n', folderPath);
    return;
end

for k = 1:length(csvFiles)
    csvPath = fullfile(csvFiles(k).folder, csvFiles(k).name);
    [~, baseName, ~] = fileparts(csvFiles(k).name);
    matPath = fullfile(csvFiles(k).folder, [baseName, '.mat']);

    % Lecture du fichier CSV sous forme de Table MATLAB (prend en charge texte et nombres)
    data = readtable(csvPath);

    % Sauvegarde de la variable 'data' dans un fichier .mat du même nom
    save(matPath, 'data');

    fprintf('Converti : %s -> %s.mat\n', csvFiles(k).name, baseName);
end

fprintf('Conversion terminée avec succès (%d fichier(s) traités).\n', length(csvFiles));
end