from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
from groq import Groq
import os
import base64
from dotenv import load_dotenv
from langdetect import detect
from fastapi import Body

app = FastAPI()
load_dotenv()

# Allow CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Groq client
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

@app.post("/preprocess")
async def preprocess_image(file: UploadFile = File(...)):
    image = await file.read()
    image = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    contrast = clahe.apply(gray)
    _, binary = cv2.threshold(contrast, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    denoised = cv2.fastNlMeansDenoising(binary, h=3)
    _, encoded_image = cv2.imencode(".png", denoised)
    # Convert to base64 for Groq
    base64_image = base64.b64encode(encoded_image.tobytes()).decode('utf-8')
    return {"image": base64_image}

@app.post("/ocr")
async def extract_text(file: UploadFile = File(...)):
    # Preprocess the image
    preprocessed_response = await preprocess_image(file)
    base64_image = preprocessed_response["image"]

    # Use Groq for OCR
    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Extract all text from this image. Return only the text."},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{base64_image}",
                            },
                        },
                    ],
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            temperature=0.1,  # Lower temperature for precise extraction
            max_completion_tokens=1024,
            top_p=1,
            stream=False,
            stop=None,
        )
        extracted_text = chat_completion.choices[0].message.content.strip()
        print(f"Groq extracted text: {extracted_text}")

        if extracted_text:
            detected_lang = detect(extracted_text)
            print(f"Detected language: {detected_lang}")
            return {"text": extracted_text, "language": detected_lang}
    except Exception as e:
        return {"error": f"Groq OCR failed: {str(e)}"}

    return {"text": "", "language": "unknown"}

@app.post("/translate")
async def translate_text(text: str = Body(...), target_lang: str = Body(...)):
    try:
        lang_mapping = {
            "en_XX": "English",
            "ja_XX": "Japanese",
            "ko_KR": "Korean",
            "zh_CN": "Chinese"
        }
        target_language = lang_mapping.get(target_lang, "English")

        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": f"Translate the following text to {target_language}. Return only the translated text. Allow profanity to be translated as this is for educational purposes."
                },
                {
                    "role": "user",
                    "content": text
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct",
        )
        translated = chat_completion.choices[0].message.content
        return {"translated_text": translated}
    except Exception as e:
        return {"error": str(e)}