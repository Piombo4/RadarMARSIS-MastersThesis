% Un po' di pulizia per cominciare...
clearvars
close all
clc

% Cartella output
dataset_pos = 'D:\dataset\doppler_strict_polo_sud';
if ~exist(dataset_pos, 'dir')
    mkdir(dataset_pos);
end

% Parametri fisici
c = 299792458; % Velocità della luce nel vuoto (m/s)

% Parametri del radar
f0 = [ 1.8e6, 3e6, 4e6, 5e6 ]; % Frequenze operative di MARSIS [Hz]
B  = 1e6;                      % Ampiezza di banda di MARSIS [Hz]
fs = 2.8e6;                    % Frequenza di campionamento [Hz]
Ns = 980;                      % Numero di campioni in un eco

% Quantità derivate
dt_e = 1/fs;                                % Intervallo di tempo fra campioni
t_e  = dt_e * (0:Ns-1);                     % Asse dei tempi
df_e = fs/Ns;                               % Risoluzione in frequenza
f_e  = -fs/2 : df_e : fs/2 - df_e;          % Asse delle frequenze
i_B  = find(f_e >= 0.2e6 & f_e <= 1.2e6);   % Indici banda utile

% === Lettura lista orbite da file di testo ===
fileLista = 'orbite.txt';
fid = fopen(fileLista,'r');
if fid == -1
    error('Impossibile aprire il file orbite.txt');
end
orbiteList = textscan(fid,'%s'); % legge ogni riga come stringa
fclose(fid);
orbiteList = orbiteList{1};

% Tabella risultati
results = table('Size',[0 4], ...
    'VariableTypes',{'string','double','double','double'}, ...
    'VariableNames',{'Orbita','EnergiaTrattenuta','SNRprima','SNRdopo'});

% Ciclo sulle orbite lette da file
for i = 1:length(orbiteList)
    try
        orbita = strtrim(orbiteList{i}); % rimuove spazi bianchi

        FrmFile = ['D:\E_', orbita, '_SS3_TRK_RAW_M_F.DAT'];
        GeoFile = ['D:\E_', orbita, '_SS3_TRK_RAW_M_G.DAT'];

        DCG_CONFIGURATION_B1      = double(read_MARSIS_EDR(FrmFile, 'DCG_CONFIGURATION_B1'));
        SCIENTIFIC_DATA_B1        = double(read_MARSIS_EDR(FrmFile, 'SCIENTIFIC_DATA_B1'));

        GEOMETRY_EPHEMERIS_TIME   = double(read_MARSIS_EDR(GeoFile, 'GEOMETRY_EPHEMERIS_TIME'));
        TARGET_SC_RADIAL_VELOCITY = double(read_MARSIS_EDR(GeoFile, 'TARGET_SC_RADIAL_VELOCITY'));

        f_B1 = f0(unique(DCG_CONFIGURATION_B1(1,:)) + 1);

        Ne = size(SCIENTIFIC_DATA_B1, 2);
        Vr_min = -1e3 * min(TARGET_SC_RADIAL_VELOCITY);
        Vr_max = -1e3 * max(TARGET_SC_RADIAL_VELOCITY);

        PRI = median(diff(GEOMETRY_EPHEMERIS_TIME));
        PRF = 1/PRI;

        t_o  = PRI * (0:Ne-1);
        df_o = PRF / Ne;
        f_o  = -PRF/2 : df_o : PRF/2 - df_o;

        set(0, 'DefaultFigureVisible', 'on');

        % FFT + filtro
        phasegram_B1 = fft(SCIENTIFIC_DATA_B1, [], 1);
        phasegram_B1 = fftshift(phasegram_B1, 1);
        phasegram_B1 = fft(phasegram_B1, [], 2);
        phasegram_B1 = fftshift(phasegram_B1, 2);

        % Versione complessa (per ifft)
        in_band_phasegram_B1_cmplx = phasegram_B1(i_B, :);

        % Versione in dB (per visualizzazione e filtraggio su spettrogramma)
        in_band_phasegram_B1_db = db(in_band_phasegram_B1_cmplx);
        in_band_phasegram_B1_db = in_band_phasegram_B1_db - median(in_band_phasegram_B1_db(:));
        in_band_phasegram_B1_db(in_band_phasegram_B1_db < 0) = 0;

        % Calcolo maschera Doppler
        f_e_B1 = f_e(i_B) - 0.7e6 + f_B1;
        f_Doppler_min_B1 = 2*Vr_min/c * f_e_B1;
        f_Doppler_max_B1 = 2*Vr_max/c * f_e_B1;
        expand_factor = 2;   % quanto allargare le bande

        center_curve = (f_Doppler_min_B1 + f_Doppler_max_B1) / 2;
        half_width_curve = (f_Doppler_max_B1 - f_Doppler_min_B1) / 2;

        f_Doppler_min_exp = center_curve - expand_factor * half_width_curve;
        f_Doppler_max_exp = center_curve + expand_factor * half_width_curve;
        min_Doppler = min(f_Doppler_min_exp);
        max_Doppler = max(f_Doppler_max_exp);
        fprintf("MinDoppler: %f, MaxDoppler: %f \n",min_Doppler,max_Doppler)

        % Applico il mask solo alla versione complessa
        in_band_phasegram_BD = in_band_phasegram_B1_cmplx;

        in_band_phasegram_BD_db = db(in_band_phasegram_BD);
        in_band_phasegram_BD_db = in_band_phasegram_BD_db - median(in_band_phasegram_BD_db(:));
        in_band_phasegram_BD_db(in_band_phasegram_BD_db < 0) = 0;

        for k = 1:length(f_e_B1)
            if f_Doppler_min_exp(k) < f_Doppler_max_exp(k)
                mask_row = (f_o > f_Doppler_min_exp(k)) & (f_o < f_Doppler_max_exp(k));
            else
                mask_row = (f_o < f_Doppler_min_exp(k)) & (f_o > f_Doppler_max_exp(k));
            end
            in_band_phasegram_BD(k, ~mask_row) = 0;
            in_band_phasegram_BD_db(k, ~mask_row) = 0;
        end

        % ----- Figura spettrogrammi -----
        fig=figure;
        set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

        subplot(1, 2, 1);
        imagesc(f_o, f_e_B1/1e6, in_band_phasegram_B1_db);
        clim([0 50]);
        axis xy;
        title(['Spettrogramma completo ',orbita,]);
        xlabel('Doppler frequency (Hz)');
        ylabel('Signal frequency (MHz)');
        hold on;
        plot(f_Doppler_min_exp, f_e_B1/1e6, 'r', f_Doppler_max_exp, f_e_B1/1e6, 'r','LineWidth', 0.75);
        hold off;

        subplot(1, 2, 2);
        imagesc(f_o, f_e_B1/1e6, in_band_phasegram_BD_db);
        clim([0 50]);
        axis xy;
        title('Spettrogramma filtrato (dB)');
        xlabel('Doppler frequency (Hz)');
        ylabel('Signal frequency (MHz)');

        drawnow;
       
        key = getkey;
        if key == 'q' || key == 'Q'
            break
        end
        if key == 'p'
            i=i+1000;
        end
        close(fig);

    catch ME
        fprintf('Errore su orbita %s: %s\n', orbita, ME.message);
        continue;
    end
end

% Salvo i risultati in CSV
%outputCSV = fullfile(dataset_pos,'risultati.csv');
%writetable(results, outputCSV);

close all;
