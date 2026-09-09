% 1. Load sample dataset (Fisher's Iris dataset)
load fisheriris

% 2. Extract features and convert to binary classification
% (SVM fitcsvm is strictly for binary classification)
X = meas(51:150, 3:4);          % Select 100 samples, 2 features for visualization
Y = species(51:150);            % Classes: 'versicolor' and 'virginica'

% 3. Train the SVM Model with a Gaussian Kernel
SVMModel = fitcsvm(X, Y, ...
    'KernelFunction', 'rbf', ...   % Uses Radial Basis Function (Gaussian)
    'Standardize', true, ...        % Standardizes features (mean=0, variance=1)
    'ClassNames', {'versicolor', 'virginica'});

% 4. Predict on new data
newObs = [4.5, 1.5; 6.0, 2.2];
[label, score] = predict(SVMModel, newObs);

disp('Predicted Labels:');
disp(label);