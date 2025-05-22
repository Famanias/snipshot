import requests

url = "http://127.0.0.1:8000/translate"
data = {
    "text": "こんにちは世界",
    "target_lang": "en_XX"

}

response = requests.post(url, json=data)
print(response.json())


# Run with: uvicorn main:app --reload