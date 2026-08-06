% =================================================================
% Sistemas Lineales, no Lineales: Caos y Fractales 
% Doctorado en Ingenieria
% Facultad Regional Buenos Aires - Universidad Tecnologica Nacional
% Catedra Dr. Walter Legnani
% Derechos Reservados
% =================================================================
% Iteracion del mapa de Henon Heiles 
%==================================================================
clc; clear all; 
a=1.2;               % Parametro alfa (a) del mapa   
b=0.3;               % Parametro beta (b) del mapa 
x0=0.4               % Condicion inicial en x 
y0=0.2;              % Condicion inicial en y
n=200000;            % Numero maximo de iteraciones
x=zeros(1,n+1); 
y=zeros(1,n+1); 
x(1)=x0; 
y(1)=y0; 
% Ciclo principal de iteracion 
for i=1:n          
 x(i+1)=1-a*(x(i)^2)+y(i); 
 y(i+1)=b*x(i); 
end 
% Graficacion
plot(x,y,'.k','LineWidth',.5,'MarkerSize',5); 
xlabel('x(n)','FontSize',18); ylabel('y(n)','FontSize',18); 
title('Atractor de Henon','FontSize',18)