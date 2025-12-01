% Un po' di pulizia per cominciare...
clearvars
close all
clc

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

% Ciclo sulle orbite lette da file

    orbita = '07964'; % rimuove spazi bianchi

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
    %set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    subplot(1, 2, 1);
    imagesc(f_o, f_e_B1/1e6, in_band_phasegram_B1_db);
    clim([0 30]);
    axis xy;
    title(['Diagramma Doppler-frequenza ',orbita]);
    xlabel('Doppler frequency (Hz)');
    ylabel('Signal frequency (MHz)');
    hold on;
    plot(f_Doppler_min_exp, f_e_B1/1e6, 'r', f_Doppler_max_exp, f_e_B1/1e6, 'r','LineWidth', 0.75);
    hold off;
     exportgraphics(gca, fullfile([char(orbita) '.png']),'BackgroundColor', 'white');
    subplot(1, 2, 2);
    imagesc(f_o, f_e_B1/1e6, in_band_phasegram_BD_db);
    clim([0 30]);
    axis xy;
    title(['Diagramma Doppler-frequenza ',orbita]);
    xlabel('Doppler frequency (Hz)');
    ylabel('Signal frequency (MHz)');
    hold on;
    plot(f_Doppler_min_exp, f_e_B1/1e6, 'r', f_Doppler_max_exp, f_e_B1/1e6, 'r','LineWidth', 0.75);
    hold off;
    
    %exportgraphics(gca, fullfile([char(orbita) '.png']),'BackgroundColor', 'white');
    
    
    %exportgraphics(gca, fullfile([char(orbita) '.png']),'BackgroundColor', 'white');
    % ----- Retrotrasformo -----
    temp = ifftshift(in_band_phasegram_BD, 2);
    temp = ifft(temp, [], 2);
    temp = ifftshift(temp, 1);
    newMatrix = ifft(temp, [], 1);

    % ----- Calcolo energia prima e dopo -----
    E_before = sum(abs(SCIENTIFIC_DATA_B1(:)).^2);
    E_after  = sum(abs(newMatrix(:)).^2);
    fprintf('Energia trattenuta: %.2f %%\n', 100*E_after/E_before);

    % ----- Stima semplice SNR (per colonna del radargramma) -----
    Nc = size(SCIENTIFIC_DATA_B1,2);
    snr_before = nan(1,Nc);
    snr_after  = nan(1,Nc);

    for i = 1:Nc
        col_b = abs(SCIENTIFIC_DATA_B1(:,i)).^2;  % potenza
        col_a = abs(newMatrix(:,i)).^2;

        sorted_b = sort(col_b, 'descend');
        sorted_a = sort(col_a, 'descend');
        k = 5; 
        pk_b = mean(sorted_b(1:min(k,end)));
        pk_a = mean(sorted_a(1:min(k,end)));

       
        thr_b = prctile(col_b,50);
        noise_b_samples = col_b(col_b <= thr_b);
        if isempty(noise_b_samples)
            noise_b = median(col_b) + eps;
        else
            noise_b = median(noise_b_samples) + eps;
        end

        thr_a = prctile(col_a,50);
        noise_a_samples = col_a(col_a <= thr_a);
        if isempty(noise_a_samples)
            noise_a = median(col_a) + eps;
        else
            noise_a = median(noise_a_samples) + eps;
        end

        snr_before(i) = 10*log10( (pk_b + eps) / noise_b );
        snr_after(i)  = 10*log10( (pk_a + eps) / noise_a );
    end

    fprintf('SNR medio prima = %.2f dB, dopo = %.2f dB\n', mean(snr_before,'omitnan'), mean(snr_after,'omitnan'));

    % ----- Figure -----
    fig2 = figure;
    set(fig2, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    subplot(1,2,1);
    imagesc(abs(SCIENTIFIC_DATA_B1));

    axis xy;
    %title('Dati originali (IFFT senza filtro)');
    xlabel('Eco index');
    ylabel('Sample index');

    subplot(1,2,2);
    imagesc(abs(newMatrix));

    axis xy;
    %title('Dati puliti (IFFT con filtro Doppler)');
    xlabel('Eco index');
    ylabel('Sample index');

    figure;
    plot(snr_before,'b'); hold on;
    plot(snr_after,'r');
    legend('SNR prima','SNR dopo');
    xlabel('Eco index'); ylabel('SNR (dB)');
    title('Confronto SNR prima e dopo il filtro');




