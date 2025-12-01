
nomefile = 'D:\E_10737_SS3_TRK_RAW_M_G.DAT'; 
param = 'GEOMETRY_EPHEMERIS_TIME';

et = read_MARSIS_EDR(nomefile, param);
et = et - et(1); % traslo in modo che sia zero il tempo del primo impulso per vedere meglio come variano i valori di et 
delta_t = diff(et); % calcola la differenza tra un istante di trasmissione di un impulso ed il successivo
PRI = median(delta_t); % Rappresenta il pulse repetition interval, intervallo temporale tra due impulsi adiacenti
delta_PRI = round(delta_t / PRI);  % calcola quante PRI passano tra un impulso e l'altro

figure;
plot(et(2:end), delta_PRI); % plotto sulla x i valori dal secondo in poi di et e sulla y delta_PRI
xlabel('ET');
ylabel('delta_PRI');
title('Ephemeris Time');
grid on;