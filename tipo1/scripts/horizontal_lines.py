import sys
import math
import cv2 as cv
import numpy as np
from scipy.signal import find_peaks

def main(argv):
    default_file = 'D:/dataset/all_images_tipo1/12350.png'
    filename = argv[0] if len(argv) > 0 else default_file
    print("File letto:", filename)

    src = cv.imread(filename, cv.IMREAD_GRAYSCALE)
    if src is None:
        print("Errore nel caricamento dell'immagine!")
        return -1
    # Equalizzazione per migliorare il contrasto
    img_eq = cv.equalizeHist(src)
    cv.imshow("Equalized", img_eq)
    img_lines = cv.cvtColor(src, cv.COLOR_GRAY2BGR)

    # Calcolo dell'intensità media per ogni riga
    row_intensity = np.mean(img_eq, axis=1)  
    soglia = np.percentile(row_intensity, 20)  
    # Rilevamento dei picchi nell'intensità delle righe
    peaks, _ = find_peaks(row_intensity, height=soglia,distance = 5,prominence = 20)

    # Disegno delle linee orizzontali rilevate
    for y in peaks:
        cv.line(img_lines, (0, y), (src.shape[1], y), (0, 0, 255), 1)

    cv.imshow("Originale", src)
    cv.imshow("Linee da picchi d'intensità", img_lines)

    cv.waitKey(0)
    cv.destroyAllWindows()

if __name__ == "__main__":
    main(sys.argv[1:])
