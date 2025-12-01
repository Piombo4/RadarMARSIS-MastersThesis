% Un po' di pulizia per cominciare...
clearvars
close all
clc
set(0, 'DefaultFigureVisible', 'on');
% Parametri fisici
fs = 2.8e6;
ns = 980;
dt = 1/fs;
t = dt * (0:ns-1);
tau = ns * dt;
df = 1/tau;
f = -fs/2 : df : fs/2 - df;
df_e = fs/ns;
f_e  = -fs/2 : df_e : fs/2 - df_e;
c = 299792458;
orbita = '10737';
metodo = 3;
output_path = 'D:\';
try

    files = dir(fullfile('D:\nuovi radargrammi da pulire\', ['I_', orbita, '_SS3_TRK_RAW_M.DAT']));
    if isempty(files)
        error('File orbita %s non trovato', orbita);
    end
    FrmFile = fullfile(files(1).folder, files(1).name);

    ECHO_MODULUS_B1               = double(read_MARSIS_IDR(FrmFile, 'ECHO_MODULUS_B1'));
    ECHO_PHASE_B1                 = double(read_MARSIS_IDR(FrmFile, 'ECHO_PHASE_B1'));
    GEOMETRY_EPHEMERIS_TIME       = double(read_MARSIS_IDR(FrmFile, 'GEOMETRY_EPHEMERIS_TIME'));
    CENTRAL_FREQUENCY             = double(read_MARSIS_IDR(FrmFile, 'CENTRAL_FREQUENCY'));

    tokens = regexp(FrmFile, 'I_(\d+)_SS3', 'tokens');
    numero = "";
    if ~isempty(tokens)
        numero = tokens{1}{1};
    end

    Ne  = size(ECHO_MODULUS_B1, 2);
    PRI = median(diff(GEOMETRY_EPHEMERIS_TIME));
    PRF = 1 / PRI;
    f_o  = -PRF/2 : PRF/Ne : PRF/2 - PRF/Ne;

    % Matrice complessa
    complex_matrix = ECHO_MODULUS_B1 .* exp(1i * ECHO_PHASE_B1);
    complex_matrix = complex_matrix(:, any(complex_matrix ~= 0, 1));
    
     % FFT
    phasegram = fft2(complex_matrix);
    phasegram =  fftshift(phasegram);
    banda_logica = abs(f) <= 0.5e6;
    phasegram(~banda_logica, :) = 0;
    
    righe_valide = mean(abs(phasegram), 2) > 0;
    phasegram_for_filter = phasegram(righe_valide, :);


    % ===== FILTRO sulle colonne =====
    mediana_colonne = median(abs(phasegram_for_filter), 1);
    eco_idx = 1:size(abs(phasegram_for_filter),2);
    validi = eco_idx;
    switch metodo
        case 1
            soglia_min = max(mediana_colonne) * 0.1;
            validi = (mediana_colonne >= soglia_min);
        case 2
            % Metodo soglia statistica
            mu = mean(mediana_colonne);
            sigma = std(mediana_colonne);

            % Parametro regolabile: k = numero di deviazioni standard
            k = 1;
            soglia = mu + k*sigma;

            validi = (mediana_colonne >= soglia);
        case 3
            level = graythresh(mediana_colonne / max(mediana_colonne));
            soglia = level * max(mediana_colonne);
            validi = (mediana_colonne >= soglia);
        case 4
    end

    phasegram_filtered = phasegram;
    phasegram_filtered(:, ~validi) = 0;

    newMatrix = ifft2(ifftshift(phasegram_filtered));

    % ----- Stima semplice SNR (per colonna del radargramma) -----
    Nc = size(complex_matrix,2);
    snr_before = nan(1,Nc);
    snr_after  = nan(1,Nc);

    for i = 1:Nc
        col_b = abs(complex_matrix(:,i)).^2;  % potenza
        col_a = abs(newMatrix(:,i)).^2;

       sorted_b = sort(col_b, 'descend');
        sorted_a = sort(col_a, 'descend');
        k = 5; % ad esempio, prendi i 5 valori più alti
        pk_b = mean(sorted_b(1:min(k,end)));
        pk_a = mean(sorted_a(1:min(k,end)));

        % noise: mediana dei valori sotto la mediana (più robusto)
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
    
    % Visualizzazioni


    fprintf('SNR medio prima = %.2f dB, dopo = %.2f dB\n', mean(snr_before,'omitnan'), mean(snr_after,'omitnan'));
    newMatrix_dB = db(newMatrix);
    newMatrix_db_max = max(newMatrix_dB(:));
    newMatrix_db_min = newMatrix_db_max-50;

    complex_matrix_dB = db(complex_matrix);
    complex_matrix_db_max = max(complex_matrix_dB(:));
    complex_matrix_db_min = complex_matrix_db_max-50;

    fig1 = figure;
    set(fig1, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    subplot(1,2,1);
    imagesc(db(complex_matrix));
    clim([complex_matrix_db_min complex_matrix_db_max]);
    title(['Eco Complesso (abs) - Orbita ', char(numero)]);
    xlabel('Numero eco');
    ylabel('Campioni');
    subplot(1,2,2);
    imagesc(newMatrix_dB);
    clim([newMatrix_db_min newMatrix_db_max]);
    title(['Matrice retrotrasformata filtrata - Orbita ', char(numero)]);
    xlabel('Eco index');
    ylabel('Sample index');

    fig2 =figure;
    set(fig2, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    subplot(3,2,1);
    imagesc(f_o, f_e/1e6, db(phasegram));
    axis xy
    title(['Eco Complesso (abs) - Orbita ', char(numero)]);
    xlabel('frequenza Doppler (Hz)');
    ylabel('tempo di volo / profondità');
    subplot(3,2,2);
    plot(eco_idx, mediana_colonne);
    xlabel('Indice eco');
    ylabel('Mediana');
    title('Mediana per eco');
    
    subplot(3,2,3);
    imagesc(f_o, f_e/1e6, db(phasegram_filtered));
    axis xy
    title(['Eco Complesso (filtrato) - Orbita ', char(numero)]);
    xlabel('frequenza Doppler (Hz)');
    ylabel('tempo di volo / profondità');
    
     figure;
    imagesc(db(complex_matrix(380:500,:)));
    clim([complex_matrix_db_min complex_matrix_db_max]);
    xlabel('Echi');
    ylabel( 'Echo time (microseconds)' )
    

    
    figure;
    imagesc(newMatrix_dB);
    clim([newMatrix_db_min newMatrix_db_max]);
    xlabel('Echi');
    ylabel( 'Echo time (microseconds)' )
       
    
     

    figure;
    imagesc(db(complex_matrix));
    colormap("gray")
    xlabel('Echi');
    ylabel( 'Echo time (microseconds)' )
     exportgraphics(gca, fullfile([char(numero) '.png']),'BackgroundColor', 'white');



catch ME
    fprintf('Errore su orbita: %s\n', ME.message);
end
i=i+1;
