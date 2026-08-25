load('prueba_suma_senoides_2.mat')
load('prueba_tipo_chirp_3.mat')
load('seno_monofrecuencial.mat')



N=length(f);
fft_f = fft(f);
fft_g = fft(g);
fft_h = fft(h);


dt = 1;
delta_f= 1/dt;
frec = 0:(N-1);
frec = delta_f/N*frec;
frec2 = frec - delta_f/2;
amplitud_f = abs(fft_f);
%%fase = angle(imag(fft_y)./real(fft_y));
amplitud_g = abs(fft_g);
amplitud_h = abs(fft_h);

figure(1)
plot(f)
title('Señal en el tiempo')
xlabel('Tiempo')
ylabel('Amplitud de la señal')
figure(2)
plot(frec,amplitud_f)
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT')
%figure(3)
%plot(frec,fase)
%title('Espectro de Fase')
%xlabel('Frecuencia')
%ylabel('Fase de la FFT')

figure(4)
plot(frec2,fftshift(amplitud_f))
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT de "f"')


figure(5)
plot(frec2,fftshift(amplitud_g))
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT de "g"')

figure(6)
plot(frec,amplitud_f)
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT')
axis([0 delta_f/2 0 max(amplitud_f)])



figure(7)
plot(frec,amplitud_g)
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT')
axis([0 delta_f/2 0 max(amplitud_g)])

figure(8)
plot(frec,amplitud_h)
title('Espectro de Amplitud')
xlabel('Frecuencia')
ylabel('Amplitud de la FFT')
axis([0 delta_f/2 0 max(amplitud_h)])

