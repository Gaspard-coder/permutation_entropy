
% =========================================================================
%  Calculo de la entropia de permutacion, entropia de renyi y de Tsalis
%
% Input
%           y: serie temporal;
%           m: orden de la entropia de permutacion
%           t: tiempo de delay de la entropia de permutacion 
%
% Output 
%           pe:    entropia de permuacion (Bandt and Pompe)
%           re:    entropia de Renyi
%           te:    entropia de Tsalis
%           hist:  histograma para el orden de la distribucion
%
% Referencias
% Ref: G Ouyang, J Li, X Liu, X Li, Dynamic Characteristics of Absence EEG Recordings with Multiscale Permutation %                             
% Entropy Analysis, Epilepsy Research, doi: 10.1016/j.eplepsyres.2012.11.003
% X Li, G Ouyang, D Richards, Predictability analysis of absence seizures with permutation entropy,     
% EpilepsyResearch,  Vol. 77pp. 70-74, 2007
% =========================================================================

function [pe re te hist] = pec(y,m,t)

ly = length(y);
permlist = perms(1:m);
c(1:length(permlist))=0;
alpha = 0.99;
q = 0.99;
 for j=1:ly-t*(m-1)
     [a,iv]=sort(y(j:t:j+t*(m-1)));
     for jj=1:length(permlist)
         if (abs(permlist(jj,:)-iv))==0
             c(jj) = c(jj) + 1 ;
         end
     end
 end

hist = c;
 
c=c(find(c~=0));
p = c/sum(c);
pe = -sum(p .* log2(p))/factorial(m); % linea original
re = (1/(1-alpha))*log(sum(p.^alpha)); %se usa log en lugar de log2 para
% comparar con la entropia de tsalis
te = (1/(q-1))*(1-sum(p.^q));
%te = -(1/(q-1))*(sum(p-(p).^q));
 
 
%WEL pe = -sum(p .* log2(p));  no normalizado




