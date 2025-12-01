clc;
clearvars;

files = dir(fullfile('D:\', '*_F.DAT'));
paramEchi = 'SCIENTIFIC_DATA_B1';
paramOrbite = 'ORBIT_NUMBER';
dataset_pos = ['D:\dataset\tipo1\'];

%parametri radar
fs = 2.8e6; %frequenza campione3amento
ns = 980; %numero di campioni per eco
dt = 1/fs; %distanza temporale tra i campioni dell'eco
t = dt * (0:ns-1); %asse dei tempi per l'eco
tau = ns * dt; %durata totale dell'eco
df = 1/tau; %spaziatura dei campioni dello spettro di fourier
f = -fs/2 : df : fs/2 -df; %asse delle frequenze per l'eco
dots = 0;
constellations = 0;
empty = 0;
i=1;
while i <= length(files)
    filedati = fullfile(files(i).folder, files(i).name);
    tokens = regexp(filedati, 'E_(\d+)_SS3', 'tokens');
    numero = "";
    if ~isempty(tokens)
        numero = tokens{1}{1};
    end

    matrix = double(read_MARSIS_EDR(filedati, paramEchi));

    fft_cols = fft(matrix,[],1);
    fft_cols = fftshift(fft_cols,1);
    inoise = find(abs(f) > 1.2e6 | abs(f) < 0.2e6);
    fft_cols(inoise,:) = 0;

    fft_rows = fft(fft_cols,[],2);
    fft_rows = fftshift(fft_rows,2);
    fft_rows = fft_rows(1:ns/2, :);
    fft_rows = fft_rows(any(fft_rows ~= 0, 2), :);

    %fft_rows_abs = db(fft_rows);
    %med_val = median(fft_rows_abs(:));
    %mask = fft_rows_abs < med_val;
    %fft_rows(mask) = med_val;

    fft_rows = db(fft_rows);
    fft_rows = fft_rows - median( fft_rows(:) );
    fft_rows( fft_rows < 0 ) = 0;
    fig = figure;

    imagesc(fft_rows);

    clim([0 25]);
    colormap(hot)

    axis off;
    k = getkey;

    if k == 'a'
       exportgraphics(gca, fullfile(char(dataset_pos), '/dots', [char(numero) '.png']), 'BackgroundColor', 'white');
        dots = dots + 1;
        disp("Dots: " + num2str(dots) + " - Constellations: " + num2str(constellations) + " - Empty: " + num2str(empty));
        i = i + 1;
    elseif k=='s'
        exportgraphics(gca, fullfile(char(dataset_pos), '/constellation', [char(numero) '.png']), 'BackgroundColor', 'white');
        constellations = constellations + 1;
        disp("Dots: " + num2str(dots) + " - Constellations: " + num2str(constellations) + " - Empty: " + num2str(empty));
        i = i + 1;
    %elseif k=='d'
        %exportgraphics(gca, fullfile(char(dataset_pos), '/empty', [char(numero) '.png']), 'BackgroundColor', 'white');
        %empty = empty + 1;
        %disp("Dots: " + num2str(dots) + " - Constellations: " + num2str(constellations) + " - Empty: " + num2str(empty));
        %i = i + 1;assssssssssssssssss
    elseif k == 'q'
        disp("Terminazione manuale.");
        break;
    elseif k == 'p'
        disp("Skippo 500 immagini");
        i = i + 500;
    else
        disp("Immagine ignorata.");
        i = i + 1;
    end

    close all;
end

close all;
disp("Finito");