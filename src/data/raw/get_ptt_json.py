import os

TARGET_DIR = 'ptt_taiwan'
ZIPFILE = TARGET_DIR + '.zip'

with open("ptt_paths.txt") as f:
    paths = [p.strip() for p in f]

# Copy file to dir
os.system(f"mkdir {TARGET_DIR}")
for p in paths: os.system(f"cp {p} {TARGET_DIR}/")

# Zip
#os.system(f"zip -r {ZIPFILE}.zip {TARGET_DIR}/")
