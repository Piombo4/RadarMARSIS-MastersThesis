% Un po' di pulizia per cominciare...
clearvars
close all
clc

% Parametri fisici
c = 299792458; % Velocità della luce nel vuoto (m/s)

% Parametri del radar
f0 = [ 1.8e6, 3e6, 4e6, 5e6 ]; % Frequenze operative di MARSIS [Hz]
B  = 1e6;                      % Ampiezza di banda di MARSIS [Hz]
fs = 2.8e6;                    % Frequenza di campionamento del convertitore analogico digitale [Hz]
Ns = 980;                      % Numero di campioni in un eco

% Quantità derivate
dt_e = 1/fs;                                % Intervallo di tempo tra due campioni dell'eco successivi [s]
t_e  = dt_e * ( 0 : Ns-1 );                 % Asse dei tempi per un eco [s]
df_e = fs/Ns;                               % Intervallo fra le frequenze della FFT dell'eco [Hz]
f_e  = -fs/2 : df_e : fs/2 - df_e;          % Asse delle frequenze per la FFT dell'eco [Hz]
i_B  = find( f_e >= 0.2e6 & f_e <= 1.2e6 ); % Indice delle componenti della FFT dell'eco che cadono nella banda del segnale

% Lettura dei dati di ingresso
% FrmFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1071X\E_10711_SS3_TRK_RAW_M_F.DAT';
% GeoFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1071X\E_10711_SS3_TRK_RAW_M_G.DAT';
% FrmFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1073X\E_10737_SS3_TRK_RAW_M_F.DAT';
% GeoFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1073X\E_10737_SS3_TRK_RAW_M_G.DAT';
% FrmFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1096X\E_10961_SS3_TRK_RAW_M_F.DAT';
% GeoFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1096X\E_10961_SS3_TRK_RAW_M_G.DAT';
% FrmFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1268X\E_12685_SS3_TRK_RAW_M_F.DAT';
% GeoFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1268X\E_12685_SS3_TRK_RAW_M_G.DAT';
% FrmFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1275X\E_12759_SS3_TRK_RAW_M_F.DAT';
% GeoFile = 'H:\Il mio Drive\MARSIS_DATA\L1B_Data\DATA\EDR1275X\E_12759_SS3_TRK_RAW_M_G.DAT';

%orbita 
orbita='02727';
FrmFile = ['D:\E_', orbita, '_SS3_TRK_RAW_M_F.DAT']; 
GeoFile = ['D:\E_', orbita, '_SS3_TRK_RAW_M_G.DAT']; 

DCG_CONFIGURATION_B1      = double( read_MARSIS_EDR( FrmFile,      'DCG_CONFIGURATION_B1' ) );
SCIENTIFIC_DATA_B1        = double( read_MARSIS_EDR( FrmFile,        'SCIENTIFIC_DATA_B1' ) );
DCG_CONFIGURATION_B2      = double( read_MARSIS_EDR( FrmFile,      'DCG_CONFIGURATION_B2' ) );
SCIENTIFIC_DATA_B2        = double( read_MARSIS_EDR( FrmFile,        'SCIENTIFIC_DATA_B2' ) );

GEOMETRY_EPHEMERIS_TIME   = double( read_MARSIS_EDR( GeoFile,   'GEOMETRY_EPHEMERIS_TIME' ) );
TARGET_SC_RADIAL_VELOCITY = double( read_MARSIS_EDR( GeoFile, 'TARGET_SC_RADIAL_VELOCITY' ) );

% Quantità derivate
f_B1   = f0( unique(DCG_CONFIGURATION_B1(1,:)) + 1 ); % Frequenza di trasmissione della prima banda [Hz]
f_B2   = f0( unique(DCG_CONFIGURATION_B2(2,:)) + 1 ); % Frequenza di trasmissione della seconda banda [Hz]

Ne     = size( SCIENTIFIC_DATA_B1, 2 );               % Number of echoes in the observation, numero di colonne matrice echi

Vr_min = -1e3 * min(TARGET_SC_RADIAL_VELOCITY);       % Minima velocità radiale della sonda durante l'osservazione [m/s]
Vr_max = -1e3 * max(TARGET_SC_RADIAL_VELOCITY);       % Massima velocità radiale della sonda durante l'osservazione [m/s]

% Calcolo del Pulse Repetition Interval e della Pulse Repetition Frequency
PRI = median( diff( GEOMETRY_EPHEMERIS_TIME ) );
PRF = 1/PRI;
% Quantità derivate
t_o  = PRI * ( 0 : Ne-1 );           % Asse dei tempi per l'osservazione [s]
df_o = PRF/Ne;                       % Intervallo fra le frequenze della FFT dell'osservazione [Hz]
f_o  = -PRF/2 : df_o : PRF/2 - df_o; % Asse delle frequenze per la FFT dell'osservazione [Hz]
% Calcolo dei fasegrammi
phasegram_B1 = fft(      SCIENTIFIC_DATA_B1, [], 1 );
phasegram_B1 = fftshift( phasegram_B1,           1 );
phasegram_B1 = fft(      phasegram_B1,       [], 2 );
phasegram_B1 = fftshift( phasegram_B1,           2 );

phasegram_B2 = fft(      SCIENTIFIC_DATA_B2, [], 1 );
phasegram_B2 = fftshift( phasegram_B2,           1 );
phasegram_B2 = fft(      phasegram_B2,       [], 2 );
phasegram_B2 = fftshift( phasegram_B2,           2 );

% Visualizzazione dei fasegrammi
subplot( 1, 2, 1 ), imagesc( f_o, f_e/1e6, db( phasegram_B1 ) )
axis xy
title( [ 'Phasegram for first band (', num2str( f_B1/1e6 ), ' MHz)' ] )
xlabel( 'Doppler frequency (Hz)' )
ylabel( 'Signal frequency (MHz)' )

subplot( 1, 2, 2 ), imagesc( f_o, f_e/1e6, db( phasegram_B2 ) )
axis xy
title( [ 'Phasegram for second band (', num2str( f_B2/1e6 ), ' MHz)' ] )
xlabel( 'Doppler frequency (Hz)' )
ylabel( 'Signal frequency (MHz)' )

% Estrazione dei fasegrammi nella banda del segnale, conversione in dB e
% normalizzazione
in_band_phasegram_B1 = phasegram_B1( i_B, : );
in_band_phasegram_B1 = db( in_band_phasegram_B1 );
in_band_phasegram_B1 = in_band_phasegram_B1 - median( in_band_phasegram_B1(:) ); %tutto si centra sulla mediana, mettendo in risalto solo i segnali più forti.
in_band_phasegram_B1( in_band_phasegram_B1 < 0 ) = 0; %elimina il rumore residuo e mantiene solo segnali "forti".

in_band_phasegram_B2 = phasegram_B2( i_B, : );
in_band_phasegram_B2 = db( in_band_phasegram_B2 );
in_band_phasegram_B2 = in_band_phasegram_B2 - median( in_band_phasegram_B2(:) );%tutto si centra sulla mediana, mettendo in risalto solo i segnali più forti.
in_band_phasegram_B2( in_band_phasegram_B2 < 0 ) = 0; %elimina il rumore residuo e mantiene solo segnali "forti".

% Creazione degli assi delle frequenze dei fasegrammi nella banda del
% segnale, calcolo delle frequenze Doppler corrispondenti
f_e_B1 = f_e( i_B ) - 0.7e6 + f_B1;
f_e_B2 = f_e( i_B ) - 0.7e6 + f_B2;

f_Doppler_min_B1 = 2*Vr_min/c * f_e_B1;
f_Doppler_max_B1 = 2*Vr_max/c * f_e_B1;
f_Doppler_min_B2 = 2*Vr_min/c * f_e_B2;
f_Doppler_max_B2 = 2*Vr_max/c * f_e_B2;

% Visualizzazione dei fasegrammi
figure

subplot( 1, 2, 1 ), imagesc( f_o, f_e_B1/1e6, in_band_phasegram_B1 )
clim( [ 0 50 ] ) %tutti i valori < 0 saranno mostrati con il colore più scuro, tutti i valori > 40 con il colore più chiaro.
colorbar
axis xy
title( [ 'In-band phasegram for first band (', num2str( f_B1/1e6 ), ' MHz)' ] )
xlabel( 'Doppler frequency (Hz)' )
ylabel( 'Signal frequency (MHz)' )

hold on
plot( f_Doppler_min_B1, f_e_B1/1e6, 'r', f_Doppler_max_B1, f_e_B1/1e6, 'w' )
hold off

subplot( 1, 2, 2 ), imagesc( f_o, f_e_B2/1e6, in_band_phasegram_B2 )
clim( [ 0 50 ] )
colorbar
axis xy
title( [ 'In-band phasegram for first band (', num2str( f_B2/1e6 ), ' MHz)' ] )
xlabel( 'Doppler frequency (Hz)' )
ylabel( 'Signal frequency (MHz)' )

hold on
plot( f_Doppler_min_B2, f_e_B2/1e6, 'r', f_Doppler_max_B2, f_e_B2/1e6, 'w' )
hold off