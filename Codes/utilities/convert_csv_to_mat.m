function convert_csv_to_mat(folderPath)
% CONVERT_CSV_TO_MAT Convertit tous les fichiers .csv d'un dossier en .mat
% et les enregistre dans un sous-dossier spécifique : <nomdudossier>_mat_table
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

% Récupération du nom du dossier de travail (ex: "DBT2")
[~, folderName] = fileparts(folderPath);
if isempty(folderName) % Gestion du cas où folderPath est la racine d'un disque
    folderName = 'dossier';
end

% Création du nom du dossier de sortie (<nomdudossier>_mat_table)
outputFolder = fullfile(folderPath, [folderName, '_mat_table']);

% Création du dossier s'il n'existe pas
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Conversion des fichiers
for k = 1:length(csvFiles)
    csvPath = fullfile(csvFiles(k).folder, csvFiles(k).name);
    [~, baseName, ~] = fileparts(csvFiles(k).name);
    
    % Le fichier .mat est orienté vers le nouveau dossier de sortie
    matPath = fullfile(outputFolder, [baseName, '.mat']);

    % Lecture du fichier CSV sous forme de Table MATLAB
    data = readtable(csvPath);

    % Sauvegarde de la variable 'data' dans le fichier .mat
    save(matPath, 'data');

    fprintf('Converti : %s -> %s\n', csvFiles(k).name, matPath);
end

fprintf('Conversion terminée avec succès (%d fichier(s) traités).\n', length(csvFiles));
fprintf('Fichiers enregistrés dans : %s\n', outputFolder);
end