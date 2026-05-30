import os
import zipfile
import kaggle
from google.cloud import storage

RAW_DIR = "./data/raw"
BUCKET_NAME = "retail-demand-pl-bronze"
GCS_PREFIX = "m5/bronze"

FILES = [
    "sales_train_validation.csv",
    "calendar.csv",
    "sell_prices.csv",
]

def download_m5():
    os.makedirs(RAW_DIR, exist_ok=True)
    print("Téléchargement du dataset M5...")
    kaggle.api.competition_download_files(
        "m5-forecasting-accuracy",
        path=RAW_DIR,
        quiet=False
    )
    zip_files = [f for f in os.listdir(RAW_DIR) if f.endswith(".zip")]
    if not zip_files:
        raise FileNotFoundError(f"No zip file found in {RAW_DIR} after download")
    print("Extraction...")
    for zip_name in zip_files:
        zip_path = os.path.join(RAW_DIR, zip_name)
        with zipfile.ZipFile(zip_path, "r") as z:
            z.extractall(RAW_DIR)
        os.remove(zip_path)
    print("Extraction terminée.")

def upload_to_gcs():
    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    for filename in FILES:
        local_path = os.path.join(RAW_DIR, filename)
        if not os.path.exists(local_path):
            print(f"Fichier manquant : {filename}, skip.")
            continue
        blob_path = f"{GCS_PREFIX}/{filename}"
        blob = bucket.blob(blob_path)
        print(f"Upload {filename} → gs://{BUCKET_NAME}/{blob_path}")
        blob.upload_from_filename(local_path)
        print(f"✓ {filename} uploadé.")

if __name__ == "__main__":
    download_m5()
    upload_to_gcs()
    print("Ingestion M5 terminée.")