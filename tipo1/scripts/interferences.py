#!/usr/bin/env python3
import cv2
import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.linear_model import RANSACRegressor
import os
from scipy.signal import find_peaks
from ultralytics import YOLO
import concurrent.futures

model = YOLO('D:/dataset/tipo1/runs/detect/train/weights/best.pt')

path = "D:/dataset/all_images_tipo1"
#os.makedirs("D:/dataset/tipo1/outputs/", exist_ok=True)
output_dir = "D:/dataset/tipo1/txts_tipo1"
os.makedirs(output_dir, exist_ok=True)

def process_image(f):
   
    filepath = os.path.join(path, f)
    img_gray = cv2.imread(filepath, cv2.IMREAD_GRAYSCALE)
    if img_gray is None:
        print(f"Impossibile leggere l'immagine: {filepath}")
        return
    if len(img_gray.shape) != 2:
        img_gray = img_gray[:, :, 0]
    
    img_filt = cv2.equalizeHist(img_gray)
    row_intensity = np.mean(img_filt, axis=1)
    soglia = np.percentile(row_intensity, 20)
    peaks, _ = find_peaks(row_intensity, height=soglia, distance=5, prominence=20)

    h,w = img_gray.shape
    top_half = img_gray[:h//2, :]
    bottom_half = img_gray[h//2:, :]
    bottom_filtered = cv2.bilateralFilter(bottom_half, d=9, sigmaColor=50, sigmaSpace=50)
    top_filtered = cv2.bilateralFilter(top_half, d=9, sigmaColor=15, sigmaSpace=15)

    img_filt = np.vstack((top_filtered, bottom_filtered))

    _, thresh = cv2.threshold(img_filt, 170, 255, cv2.THRESH_BINARY)
    thresh = cv2.dilate(thresh, None, iterations=3)
    mask = np.zeros_like(img_filt, dtype=np.uint8)
    mask[:, 380:] = 1
    img_masked = cv2.bitwise_and(thresh, thresh, mask=mask)

    points = np.column_stack(np.where(img_masked.transpose() > 0))
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
    if centers.shape[0] < 2 or centers.shape[1] != 2:
        print(f"Immagine {f}: troppi pochi centri per regressione o shape errato: {centers.shape}")
        return
    X = centers[:, 0].reshape(-1, 1)
    y = centers[:, 1]

    model_line = RANSACRegressor(residual_threshold=25)
    model_line.fit(X, y)

    line_x = np.linspace(X.min(), X.max(), 100).reshape(-1, 1)
    line_y = model_line.predict(line_x)

    point1 = (int(line_x[0][0]), int(line_y[0]))
    point2 = (int(line_x[-1][0]), int(line_y[-1]))
    slope = (point2[1] - point1[1]) / (point2[0] - point1[0])

    img_out = cv2.cvtColor(img_gray, cv2.COLOR_GRAY2BGR)
    
    results = model.predict(source=filepath, save=False)

    #for y in peaks:
        #cv2.line(img_out, (0, y), (img_gray.shape[1], y), (0, 0, 255), 1)

    #if slope > 1.5 and slope <2.6:
        #for i in range(len(line_x) - 1):
            #cv2.line(img_out, (int(line_x[i].item()), int(line_y[i].item())),
                        #(int(line_x[i + 1].item()), int(line_y[i + 1].item())),
                    #(255, 0, 0), 2)
    
   # for r in results:
        #boxes = r.boxes.xyxy.cpu().numpy().astype(int)
        #scores = r.boxes.conf.cpu().numpy()
        #for box, score in zip(boxes, scores):
            #if score <0.3:
                #continue
            #x1, y1, x2, y2 = box
            #cv2.rectangle(img_out, (x1, y1), (x2, y2), (0, 255, 0), 2)
    
    
    output_txt = os.path.join(output_dir, f"{os.path.splitext(f)[0]}.txt")
    with open(output_txt, "w") as f_out:
        
        if slope > 1.5 and slope <2.6:
            f_out.write("Inizio e fine costellazione: ")   
            f_out.write(f"({point1[0]},{point1[1]}) ({point2[0]},{point2[1]})\n")
            f_out.write("------------------------------------------\n") 
        
        
        f_out.write("Righe orizzontali: \n")   
        f_out.write(", ".join(map(str, peaks)))
        f_out.write("\n")
        f_out.write("------------------------------------------\n")
        
        f_out.write("Bounding box puntino: ")   
        for r in results:
            boxes = r.boxes.xyxy.cpu().numpy().astype(int)
            scores = r.boxes.conf.cpu().numpy()
            for box, score in zip(boxes, scores):
                if score <0.3:
                    continue
                x1, y1, x2, y2 = box
                f_out.write(f"({x1},{y1}) ({x2},{y2})\n")

    #cv2.imwrite(os.path.join("outputs/", f"{f}"), img_out)

print("Avvio script")

if not os.path.exists(path):
    print(f"Path non trovato: {path}")
    exit()

images = os.listdir(path)
print(f"Trovate {len(images)} immagini nella cartella: {path}")

if not images:
    print("Nessuna immagine trovata.")
    exit()

def safe_process_image(f):
    try:
        print(f"Inizio elaborazione: {f}")
        process_image(f)
        print(f"Fine elaborazione: {f}")
    except Exception as e:
        print(f"Errore in {f}: {e}")

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    executor.map(safe_process_image, images)