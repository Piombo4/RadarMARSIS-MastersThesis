#!/usr/bin/env python3
import cv2
import numpy as np
from skimage import measure, color

img_path = "D:/dataset/all_dots/12476.png"

# Leggi e converti immagine
img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)   
image = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)  

# Filtro per ridurre rumore preservando i bordi
img_filt = cv2.bilateralFilter(img, d=7, sigmaColor=40, sigmaSpace=55)

# Soglia statica 
_, thresh = cv2.threshold(img_filt, 188, 255, cv2.THRESH_BINARY)

# Dilatazione per unire contorni frammentati
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (6, 6))
thresh = cv2.dilate(thresh, kernel, iterations=1)

# Etichettatura connessi
labels = measure.label(thresh, connectivity=2, background=0)
label_image = color.label2rgb(labels, bg_label=0, bg_color=(0, 0, 0), kind='overlay')

# Converti da float [0,1] a uint8 [0,255]
label_image = (label_image * 255).astype(np.uint8)

# Converti da RGB a BGR per OpenCV
label_image_bgr = cv2.cvtColor(label_image, cv2.COLOR_RGB2BGR)
cv2.imshow("Gugu", label_image_bgr)

# Parametri per scelta del miglior oggetto
best_score = -np.inf
best_mask = None
image_center = np.array([img.shape[1] // 2, img.shape[0] // 2])

for label in np.unique(labels):
    if label == 0:
        continue

    labelMask = np.zeros(thresh.shape, dtype="uint8")
    labelMask[labels == label] = 255
    numPixels = cv2.countNonZero(labelMask)

    if 120 < numPixels < 300:
        cnts, _ = cv2.findContours(labelMask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if len(cnts) == 0:
            continue

        c = cnts[0]
        perimeter = cv2.arcLength(c, True)
        area = cv2.contourArea(c)
        if perimeter == 0 or area == 0:
            continue

        # Metriche avanzate
        circularity = (4 * np.pi * area) / (perimeter ** 2)
        x, y, w, h = cv2.boundingRect(c)
        aspect_ratio = w / float(h)
        hull = cv2.convexHull(c)
        hull_area = cv2.contourArea(hull)
        solidity = area / hull_area if hull_area > 0 else 0

        # Centro massa
        M = cv2.moments(c)
        if M["m00"] == 0:
            continue
        cX = int(M["m10"] / M["m00"])
        cY = int(M["m01"] / M["m00"])
        dist_from_center = np.linalg.norm(image_center - np.array([cX, cY]))

        # Score combinato: più alto = meglio
        print(f"Solidity: {solidity:.2f}, Aspect Ratio: {aspect_ratio:.2f}, Circularity:  {circularity:.2f}")
        if (
            circularity>0.3 and
            0.2 < aspect_ratio < 1.2 and
            solidity > 0.8 
           
        ):
            
            score = circularity + 0.01 * solidity
            if score > best_score:
                best_score = score
                best_mask = labelMask.copy()
                best_contour = c
                best_coords = (cX, cY)

# Visualizzazione
if best_mask is not None:
    result = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    ((cX, cY), radius) = cv2.minEnclosingCircle(best_contour)
    cv2.circle(result, (int(cX), int(cY)), int(radius), (0, 255, 0), 2)
    cv2.putText(result, "Best", (int(cX) - 10, int(cY) - 15),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    print(f"Punto rilevato al centro ({cX},{cY}) con score={best_score:.3f}")
    cv2.imshow("Most Circular Component", result)
else:
    print(" Nessun componente valido trovato.")

cv2.imshow("Thresh", thresh)
cv2.waitKey(0)
cv2.destroyAllWindows()
