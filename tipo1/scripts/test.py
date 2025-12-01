import os

# cartella che contiene le immagini
image_folder = "D:/dataset/tipo1/YOLOdata/training/images"

# cartella che contiene i file txt
label_folder = "D:/dataset/tipo1/YOLOdata/training/labels"

# estensioni considerate immagini
image_extensions = {".png", ".jpg", ".jpeg"}

# crea la cartella delle label se non esiste
os.makedirs(label_folder, exist_ok=True)

for filename in os.listdir(image_folder):
    name, ext = os.path.splitext(filename)

    # controlla se è un'immagine
    if ext.lower() in image_extensions:
        txt_path = os.path.join(label_folder, f"{name}.txt")

        # se il file txt non esiste, crealo
        if not os.path.exists(txt_path):
            print(f"Creo: {txt_path}")
            with open(txt_path, "w") as f:
                pass  # file vuoto

print("Operazione completata.")
