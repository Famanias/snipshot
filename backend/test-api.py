import requests
response = requests.post(
    "http://127.0.0.1:8000/ocr",
    files={"file": open("C:\Users\PC\Desktop\thesis\snipshot\backend\manga.png", "rb")}
)
print(response.json())