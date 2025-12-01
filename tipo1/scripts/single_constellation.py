import cv2
import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.linear_model import RANSACRegressor
import matplotlib.pyplot as plt


img_path = "D:/dataset/all_images_tipo1/04202.png"

img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
if img is None:
    print(f"Errore: Immagine non trovata al percorso {img_path}")
    exit()

h, w = img.shape

# Filtro bilaterale separato 
top_half = img[:h//2, :]
bottom_half = img[h//2:, :]
bottom_filtered = cv2.bilateralFilter(bottom_half, d=9, sigmaColor=45, sigmaSpace=45)
top_filtered = cv2.bilateralFilter(top_half, d=9, sigmaColor=15, sigmaSpace=15)
img_eq = np.vstack((top_filtered, bottom_filtered))

# Thresholding, Dilatazione e Masking 
_, thresh = cv2.threshold(img_eq, 170, 255, cv2.THRESH_BINARY)
thresh = cv2.dilate(thresh, None, iterations=3) 
cv2.imshow("Thresholded", thresh)
mask = np.zeros_like(img, dtype=np.uint8)
# Applico la maschera solo a destra 
mask[:, 380:] = 1 
img_masked = cv2.bitwise_and(thresh, thresh, mask=mask)
cv2.imshow("Thresholded", img_masked)
points = np.column_stack(np.where(img_masked.transpose() > 0)) 

# Clustering DBSCAN 
clustering = DBSCAN(eps=5, min_samples=20).fit(points)
labels = clustering.labels_

centers = []
for label in set(labels):
    if label == -1:
        continue  
    cluster_points = points[labels == label]
    cx = np.mean(cluster_points[:, 0])
    cy = np.mean(cluster_points[:, 1])
    centers.append((cx, cy))

centers = np.array(centers)

if len(centers) < 2:
    print("Meno di 2 centroidi rilevati. Impossibile calcolare RANSAC e armonicità.")
    exit()

X = centers[:, 0].reshape(-1, 1)
y = centers[:, 1]

# --- RANSAC per la retta e identificazione degli Inlier ---

residual_threshold_ransac = 25 
model = RANSACRegressor(residual_threshold=residual_threshold_ransac)
model.fit(X, y)

# Identifico quali centroidi sono stati usati da RANSAC 
inlier_mask = model.inlier_mask_
outlier_mask = np.logical_not(inlier_mask)

# Centroidi che si trovano sulla retta
inlier_centers = centers[inlier_mask]

# --- Analisi Armonica ---
print("\n--- Analisi Armonica ---")

if inlier_centers.shape[0] < 2:
    print(" Nessun picco significativo sulla retta rilevato (meno di 2 inlier).")
else:
    sorted_idx = np.argsort(inlier_centers[:, 0])
    sorted_inliers = inlier_centers[sorted_idx]

    x_sorted = sorted_inliers[:, 0]
    y_sorted = sorted_inliers[:, 1]

    # Calcola distanza euclidea tra picchi consecutivi
    d = np.sqrt(np.diff(x_sorted)**2 + np.diff(y_sorted)**2)
    
    # 3. Calcola la distanza media e la deviazione standard
    mean_dx = np.mean(d)
    std_dx = np.std(d)
    
    # Stampa i risultati
    print(f'Numero di picchi sulla retta (inlier): {len(x_sorted)}')
    print(f'Distanza media tra picchi (frequenza): {mean_dx:.3f} ± {std_dx:.3f} pixel')

    # 4. Valutazione Armonicità: Se la deviazione standard è piccola rispetto alla media
    # Soglia tipica: la deviazione standard è inferiore al 5% della media
    harmonicity_threshold = 0.04
    
    if std_dx < harmonicity_threshold * mean_dx:
        print(' Spaziatura quasi costante. Compatibile con un segnale armonico.')
    else:
        print(' Spaziatura irregolare. Non compatibile con armoniche pure.')


# --- Visualizzazione (Modificata per mostrare Inlier e Outlier) ---
# Creo la retta per il disegno
line_x = np.linspace(X.min(), X.max(), 300).reshape(-1, 1)
line_y = model.predict(line_x)

# Converte l'immagine in BGR per disegnare
img_bgr = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)

# Disegna tutti i centroidi
for i, (cx, cy) in enumerate(centers):
    if inlier_mask[i]:
        # Inlier (sulla retta) in verde
        cv2.circle(img_bgr, (int(cx), int(cy)), 4, (0, 255, 0), -1) 
    else:
        # Outlier (fuori dalla retta) in rosso
        cv2.circle(img_bgr, (int(cx), int(cy)), 4, (0, 0, 255), -1) 

# Disegna la retta RANSAC in blu
point1 = (int(line_x[0][0]), int(line_y[0]))
point2 = (int(line_x[-1][0]), int(line_y[-1]))
cv2.line(img_bgr, point1, point2, (255, 0, 0), 2)

plt.figure()
plt.bar(range(len(d)), d)
plt.axhline(np.mean(d), color='r', linestyle='--', label='Media')
plt.title("Distanze tra picchi consecutivi")
plt.xlabel("Intervallo tra picchi")
plt.ylabel("Distanza [pixel]")
plt.legend()
plt.grid(True)
plt.show()

cv2.imshow("Centroidi (Verde=Inlier, Rosso=Outlier) e Retta RANSAC", img_bgr)
cv2.waitKey(0)
cv2.destroyAllWindows()