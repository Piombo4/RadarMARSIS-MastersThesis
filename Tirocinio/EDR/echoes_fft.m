clc;
close all;
clearvars;

%orbita
orbita='10737';

%parametri radar
fs = 2.8e6; %frequenza campionamento 
ns = 980; %numero di campioni per eco
dt = 1/fs; %distanza temporale tra i campioni dell'eco
t = dt * (0:ns-1); %asse dei tempi per l'eco
tau = ns * dt; %durata totale dell'eco
df = 1/tau; %spaziatura dei campioni dello spettro di fourier
f = -fs/2 : df : fs/2 -df; %asse delle frequenze per l'eco

% size(matrix) 

filedati = ['D:\E_', orbita, '_SS3_TRK_RAW_M_F.DAT']; 
paramEchi = 'SCIENTIFIC_DATA_B1';
orbit = 'OST_LINE_NUMBER_B1';

matrix = double(read_MARSIS_EDR(filedati,paramEchi));
t = read_MARSIS_EDR(filedati,orbit);

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

fft_rows = db(fft_rows);
fft_rows = fft_rows - median( fft_rows(:) );
fft_rows( fft_rows < 0 ) = 0;

fig = figure;
imagesc(db(matrix));
colormap("gray")
xlabel( 'Echi' )
ylabel( 'Echo time (microseconds)' )

exportgraphics(gca, fullfile([orbita '.png']),'BackgroundColor', 'white');

%imagesc(db(fft_rows));

%title("Orbita",orbita)
%axis off; 
%