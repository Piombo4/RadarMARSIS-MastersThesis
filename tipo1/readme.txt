../Tirocinio contiene tutti gli script di MATLAB. Il metodo di filtraggio sviluppato è nel file Tirocinio/IDR/idr_filter_single.m

/tipo1 è una cartella che contiene: /runs/detect/train -> il modello YOLO addestrato 
                                    /scripts -> gli scripts creati
                                    /YOLOdata -> il dataset YOLO
                                    data.yaml -> file di configurazione per YOLO
                                    yolov8n.pt -> il modello YOLO generato automaticamente prima dell'addestramento 

scripts/horizontal_lines.py: individua le righe orizzontali (prima tipologia di interfenze) in un'immagine
scripts/single_constellation.py: individua le righe orizzontali (seconda tipologia di interfenze) in un'immagine
scripts/single_dot.py: individua i picchi luminosi (terza tipologia di interfenze) in un'immagine tramite OpenCV
scripts/yolo_run.py: individua i picchi luminosi (terza tipologia di interfenze) tramite YOLO
scripts/interferences.py: per ogni immagine nella cartella specificata individua le tre tipologie (utilizzando YOLO per la terza tipologia) 

Comando per allenare un nuovo modello: 
yolo task=detect mode=train model=yolov8n.pt lr0=0.002 lrf=0.002 warmup_epochs=5  degrees=0.0 mixup=0.00 mosaic= 0.0 imgsz=640 workers=0 device=cpu flipud=0.0 fliplr=0.0 batch=2 epochs=100 patience=20 data=data.yaml exist_ok=true dropout=0.35 optimizer=AdamW hsv_v=0.1 translate=0.05 scale=0.1 box=0.02 cls=0.5

Comando per testare il modello allenato sul test set: 
yolo task=detect mode=val model=runs/detect/train/weights/best.pt data=data.yaml split=test



