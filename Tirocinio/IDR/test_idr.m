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

    imagesc(db(phasegram))
    xlabel('Campioni' );
    ylabel('Eco');
    exportgraphics(gca, fullfile([numero '.png']),'BackgroundColor', 'white');


catch ME
    fprintf('Errore su orbita: %s\n', ME.message);
end

