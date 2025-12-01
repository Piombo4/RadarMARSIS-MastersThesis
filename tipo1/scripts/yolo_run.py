from ultralytics import YOLO
import os

# Percorsi
model_path = 'D:/dataset/tipo1/runs/detect/train/weights/best.pt'
input_folder = 'D:/dataset/new_all_images_tipo1/'
output_folder = 'D:/dataset/output_detections/'  


os.makedirs(output_folder, exist_ok=True)

model = YOLO(model_path)

results = model.predict(
    source=input_folder,
    conf=0.565,           
    save=True,          
    project=output_folder,  
    name='yolo_detections', 
    exist_ok=True       
)


total_detections = 0

for r in results:
    n = len(r.boxes)
    total_detections += n
    print(f"Immagine: {r.path} → {n} pallini trovati")

print("\n--------------------------------")
print(f"Totale pallini luminosi individuati: {total_detections}")
print("--------------------------------")

print(f"\nLe immagini annotate sono state salvate in:\n{os.path.join(output_folder, 'yolo_detections')}")
