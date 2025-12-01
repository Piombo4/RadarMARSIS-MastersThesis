clc;
clearvars;
folder = 'D:\';
files = dir(fullfile(folder, '*_F.DAT'));
%files = files(randperm(length(files)));
paramEchi = 'SCIENTIFIC_DATA_B1';
paramOrbite = 'ORBIT_NUMBER';
dataset_pos = ['D:\dataset\new_all_images_tipo1'];

if ~exist(dataset_pos, 'dir')
    mkdir(dataset_pos);
end
metodo=1;

%parametri radar
fs = 2.8e6; %frequenza campione3amento
ns = 980; %numero di campioni per eco
dt = 1/fs; %distanza temporale tra i campioni dell'eco
t = dt * (0:ns-1); %asse dei tempi per l'eco
tau = ns * dt; %durata totale dell'eco
df = 1/tau; %spaziatura dei campioni dello spettro di fourier
f = -fs/2 : df : fs/2 -df; %asse delle frequenze per l'eco


for i = 1:length(files)
    filedati = [files(i).folder,files(i).name];

    tokens = regexp(filedati, 'E_(\d+)_SS3', 'tokens');
    numero = "";
    if ~isempty(tokens)
        numero = tokens{1}{1};

    end
    output_file = fullfile(char(dataset_pos), [char(numero) '.png']);
    if exist(output_file, 'file')

        continue;
    end

    matrix = double(read_MARSIS_EDR(filedati,paramEchi));

    fft_cols = fft(matrix,[],1);
    fft_cols = fftshift(fft_cols,1);
    inoise = find(abs(f)>1.2e6 | abs(f)<0.2e6);
    fft_cols(inoise,:) = 0;
    fft_rows = fft(fft_cols,[],2);
    fft_rows = fftshift(fft_rows,2);

    %Rimozione parte simmetrica
    fft_rows = fft_rows(1:ns/2, :);

    %Butto via le righe di zeri
    fft_rows = fft_rows(any(fft_rows ~= 0, 2), :);
    fig = figure;

    switch metodo
        case 1
            set(0, 'DefaultFigureVisible', 'off');
            fft_rows = db(fft_rows);
            fft_rows = fft_rows - median( fft_rows(:) );
            fft_rows( fft_rows < 0 ) = 0;
            %fft_rows = medfilt2(abs(fft_rows), [2 2]);
            imagesc(fft_rows);
            clim([0 30]);
            colormap(jet);
            axis off;
            exportgraphics(gca, fullfile(char(dataset_pos), [char(numero) '.png']),'BackgroundColor', 'white');

        case 2
            set(0, 'DefaultFigureVisible', 'off');
            fft_rows_abs = db(fft_rows);

            % Soglia inferiore: porta tutto sotto la mediana alla mediana
            med_val = median(fft_rows_abs(:));
            mask = fft_rows_abs < med_val;
            fft_rows(mask) = med_val;

            % Ricalcola l'assoluto dopo il primo filtro
            fft_rows_abs = db(fft_rows);

            imagesc(db(fft_rows));
            clim([med_val, med_val+20]); % range fisso ma relativo alla mediana
            axis off;
            exportgraphics(gca, fullfile(char(dataset_pos), [char(numero) '.png']),'BackgroundColor', 'white');
        case 3
            set(0, 'DefaultFigureVisible', 'off');
            M = db(fft_rows);                % Passaggio in decibel
            mu = mean(M(:));                 % Media
            sigma = std(M(:));              % Deviazione standard
            M = (M - mu) / sigma;           % Normalizzazione Z-score
            M(M < 0) = 0;                   % ignora i valori sotto la media
            M = mat2gray(M);                % Riscalamento tra 0 e 1 per display

            imagesc(M);                     % Visualizzazione
            colormap(jet);
            axis off;
            exportgraphics(gca, fullfile(char(dataset_pos), [char(numero) '.png']),'BackgroundColor', 'white');
        case 4
            fft_rows_abs = db(fft_rows);

            % Soglia inferiore: porta tutto sotto la mediana alla mediana
            med_val = median(fft_rows_abs(:));
            mask = fft_rows_abs < med_val;
            fft_rows(mask) = med_val;

            % Ricalcola l'assoluto dopo il primo filtro
            fft_rows_abs = db(fft_rows);

            % Soglia superiore: porta tutto sopra il massimo desiderato al massimo
            max_val = med_val + 10^1.5;
            mask = fft_rows_abs > max_val;
            fft_rows(mask) = max_val;
            M = db(fft_rows);
            if isempty(M)
                warning("M è vuota per il file %s", filedati);
                continue;
            elseif max(M(:)) == min(M(:))
                warning("M è costante per il file %s", filedati);
                continue;
            else
                M = mat2gray(M);
            end

            cmap = parula(256);
            rgbImage = ind2rgb(gray2ind(M, 256), cmap);
            imwrite(rgbImage, fullfile('D:/dataset/all_images/', char(numero) + ".png"));

    end
    close all;
end
close all;
disp("done");