clc;
clearvars;

files = dir(fullfile('D:\nuovi radargrammi da pulire\', '*_SS3_TRK_RAW_M.DAT'));

% Parametri radar
fs = 4e6;
ns = 980;
dt = 1/fs;
t = dt * (0:ns-1);
tau = ns * dt;
df = 1/tau;
f = -fs/2 : df : fs/2 - df;
df_e = fs/ns;
f_e  = -fs/2 : df_e : fs/2 - df_e;
c = 299792458; 

i = 1;
while i <= length(files)
    filedati = fullfile(files(i).folder, files(i).name);
    ECHO_MODULUS_B1           = double(read_MARSIS_IDR(filedati, 'ECHO_MODULUS_B1'));
    ECHO_PHASE_B1             = double(read_MARSIS_IDR(filedati, 'ECHO_PHASE_B1'));
    TARGET_SC_RADIAL_VELOCITY = double(read_MARSIS_IDR(filedati, 'TARGET_SC_RADIAL_VELOCITY'));
    GEOMETRY_EPHEMERIS_TIME   = double(read_MARSIS_IDR(filedati, 'GEOMETRY_EPHEMERIS_TIME'));

    tokens = regexp(filedati, 'I_(\d+)_SS3', 'tokens');
    numero = "";
    if ~isempty(tokens)
        numero = tokens{1}{1};
    end

    complex_matrix = ECHO_MODULUS_B1 .* exp(1i * ECHO_PHASE_B1);
    complex_matrix = complex_matrix(:, any(complex_matrix ~= 0, 1));

    % FFT colonne
    fft_cols = fft(complex_matrix,[],1);
    fft_cols = fftshift(fft_cols,1);
    banda_logica = abs(f) <= 0.5e6;
    fft_cols = fft_cols(banda_logica, :);
    
    % FFT righe
    fft_rows = fft(fft_cols,[],2);
    fft_rows = fftshift(fft_rows,2);

    % Pre-Processing
    fft_rows = db(fft_rows);
    fft_rows = fft_rows - median(fft_rows(:));
    fft_rows(fft_rows < 0) = 0;
    
    Ne  = size(ECHO_MODULUS_B1, 2);
    Vr_min = -1e3 * min(TARGET_SC_RADIAL_VELOCITY);
    Vr_max = -1e3 * max(TARGET_SC_RADIAL_VELOCITY);
    PRI = median(diff(GEOMETRY_EPHEMERIS_TIME));
    PRF = 1 / PRI;

    f_o  = -PRF/2 : PRF/Ne : PRF/2 - PRF/Ne;
    f_inband = f(banda_logica) + fs;

    f_Dmin = 2 * Vr_min / c * f_inband;
    f_Dmax = 2 * Vr_max / c * f_inband;

    % Visualizzazione affiancata
    fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    subplot(1,2,1)
    imagesc(db(complex_matrix));
    axis xy
    colormap(gca, 'parula')
    title(['Eco Complesso (dB) - Orbita ', char(numero)]);
    xlabel('Numero eco');
    ylabel('Campioni');

    subplot(1,2,2)
    imagesc(f_o, f_inband/1e6, fft_rows);
    clim([0 50]);
    axis xy
    xlabel('Frequenza Doppler (Hz)');
    ylabel('Frequenza segnale (MHz)');
    title(['Phasegram IDR - Orbita ', char(numero)]);
    colormap(gca, 'parula')
    colorbar

    hold on
    plot(f_Dmin, f_inband/1e6, 'r', 'LineWidth', 1.5);
    plot(f_Dmax, f_inband/1e6, 'w', 'LineWidth', 1.5);
    hold off

    disp("Premi ↑ per salvare l'orbita, qualsiasi altro tasto per continuare.");

    
    k = -1;
    while k == -1
        pause(0.1);  
        if ishandle(fig) && gcf == fig
            k = getkey(1); 
        else
            k = -1; 
        end
    end

    if k == 30 
        fid = fopen('orbite_salvate.txt', 'a');
        fprintf(fid, '%s\n', char(numero));
        fclose(fid);
        disp(['Salvata orbita ', char(numero)]);
    end

    close(fig);
    i = i + 1;
end

close all;
