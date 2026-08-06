function [pe pe2 pe2_normalizada] = pec(y,m,t)
% =================================================================
% Sistemas Lineales, no Lineales: Caos y Fractales 
% Doctorado en Ingenier�a
% Facultad Regional Buenos Aires - Universidad Tecnologica Nacional
% Catedra Dr. Walter Legnani
% =======================================================================
% Calculo de la entropia de permutacion y del histograma correspondiente
% Segun el metodo de Bandt y Pompe (2002)
%=========================================================================
%
%  Input:   y: time series;
%           m: orden de la entropia de permuacion
%           t: tiempo de retraso para el calculo de la entr. de permut. 
%
%  Output: 
%           pe:    entropia de permutacion usando log en base natural
%           pe2:   entropia de permutacion usando log en base 2
%           pe2_normalizada: entr. de permut. usando log en base 2 y
%           normalizando
%           hist:  histograma experimental de Band y Pompe
% Por ejemplo
%               x= [4,7,9,10,6,11,3]
%               [e e2 e2_normalizada hist] = permentropy(x,3,1)
%%=========================================================================

ly = length(y);
permlist = perms(1:m); % list of the pi permutation to compare
c(1:length(permlist))=0; % counting occurences of each permutation
    
 for j=1:ly-t*(m-1) %for each column vector
     [a,iv]=sort(y(j:t:j+t*(m-1))); % a sorted vector, iv permutation vector
     % Then looking for the matching permutation for the tablist
     for jj=1:length(permlist) 
         if (abs(permlist(jj,:)-iv))==0
             c(jj) = c(jj) + 1 ;
         end
     end
 end

hist = c;
 
c=c(find(c~=0));
p = c/sum(c);
pe = -sum(p .* log(p))/log(factorial(m));
pe2 = -sum(p.*log2(p));
pe2_normalizada = -sum(p .* log2(p))/log2(factorial(m));
