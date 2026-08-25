k= 1:1000;


%% WEL f = 2*sin(k)+1*sin(2*k)+0.5*sin(10*k);
f = 1*sin(k)+1*sin(2*k);


h = sin(k);

%g(1:300) = 2*sin(k(1:300));
%g(301:600)= 5*sin(5*k(301:600));
%g(601:1000)= 10 *sin(10*k(601:1000));

g(1:600) = 1*sin(k(1:600));
g(601:1000)= 1*sin(100*k(601:1000));
%g(601:1000)= 1*sin(10*k(601:1000));



save prueba_tipo_chirp_3 g
save prueba_suma_senoides_2 f


save seno_monofrecuencial_2 h