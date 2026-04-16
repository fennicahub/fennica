## use this code to convert xml to csv https://github.com/hsci-r/bibxml2

##Step 1. Load .xml from pouta 
import requests
import zipfile
import os

url = "https://a3s.fi/swift/v1/fennica-container/Fennica_bibliot_20260413.zip"
zip_path = "fennica.zip"
extract_to = "fennica_data_16042026"

# download (streaming)
with requests.get(url, stream=True) as r:
    r.raise_for_status()
    with open(zip_path, "wb") as f:
        for chunk in r.iter_content(chunk_size=8192):
            f.write(chunk)

# unzip
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_to)

print("Done")

#intsall bibxml2 
# run bibxml2 file_name.xml -o file_name.csv