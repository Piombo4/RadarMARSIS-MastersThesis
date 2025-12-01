function [centroids, pks] = findClusteredPeaks(A_db, threshold_dB, minDist)
% findClusteredPeaks - trova picchi su matrice complessa A (in dB) e clusterizza
% USO:
%   [centroids, pks] = findClusteredPeaks(A)
%   [centroids, pks] = findClusteredPeaks(A, threshold_dB, minDist)
%
% INPUT:
%   A            - matrice (complessa)
%   threshold_dB - soglia rispetto al massimo in dB (default 10)
%   minDist      - distanza minima in pixel per considerare separati i picchi (default 3)
%
% OUTPUT:
%   centroids - Nx2 array: [x y] dei centroidi (colonna, riga)
%   pks       - Nx1 vettore dei massimi in dB per ciascun cluster

    % defaults
    if nargin < 2 || isempty(threshold_dB)
        threshold_dB = 10;
    end
    if nargin < 3 || isempty(minDist)
        minDist = 3;
    end

    % validazione e conversione per strel
    if ~isnumeric(minDist) || ~isfinite(minDist) || minDist < 0
        error('minDist deve essere un numero reale >= 0');
    end
    % strel richiede un intero; usiamo ceil per non ridurre la distanza desiderata
    seRadius = ceil(minDist);

    % trova massimi locali 2D
    BW = imregionalmax(A_db);

    % filtra con soglia relativa al massimo
    BW = BW & (A_db >= max(A_db(:)) - threshold_dB);

    % se non ci sono pixel attivi, ritorna vuoto
    if ~any(BW(:))
        centroids = zeros(0,2);
        pks = zeros(0,1);
        return;
    end

    % dilata per unire picchi troppo vicini; usa disco con raggio seRadius
    if seRadius > 0
        se = strel('disk', seRadius);
        BW_clustered = imdilate(BW, se);
        BW_clustered = imclose(BW_clustered, se);  % opzionale ma aiuta a chiudere buchi
    else
        BW_clustered = BW;
    end

    % etichetta i cluster
    L = logical(BW_clustered);

    % calcola centroidi pesati e intensità massima per ogni cluster
    stats = regionprops(L, A_db, 'WeightedCentroid', 'MaxIntensity');

    if isempty(stats)
        centroids = zeros(0,2);
        pks = zeros(0,1);
        return;
    end

    % estrai risultati
    centroids = cat(1, stats.WeightedCentroid); % formato [x y]
    pks = [stats.MaxIntensity]';

end
