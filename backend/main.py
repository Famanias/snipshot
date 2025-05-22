from fastapi import FastAPI, Body, Form # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import cv2 # type: ignore
import numpy as np # type: ignore
from groq import Groq # type: ignore
import os
import base64
from dotenv import load_dotenv # type: ignore
from langdetect import detect # type: ignore
from pydantic import BaseModel # type: ignore

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
async def preprocess_image(image_bytes: bytes = Form(...)):
    image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    contrast = clahe.apply(gray)
    _, binary = cv2.threshold(contrast, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    denoised = cv2.fastNlMeansDenoising(binary, h=3)
    _, encoded_image = cv2.imencode(".png", denoised)
    # Convert to base64 for Groq
    base64_image = base64.b64encode(encoded_image.tobytes()).decode('utf-8')
    return {"image": base64_image}

class OCRRequest(BaseModel):
    image_base64: str

@app.post("/ocr")
async def extract_text(request: OCRRequest):
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(request.image_base64)
        preprocessed_response = await preprocess_image(image_bytes)
        base64_image = preprocessed_response["image"]

        # OCR via Groq
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
            temperature=0.1,
            max_completion_tokens=1024,
        )
        extracted_text = chat_completion.choices[0].message.content.strip()
        detected_lang = detect(extracted_text)
        return {"text": extracted_text, "language": detected_lang}
    except Exception as e:
        return {"error": f"OCR failed: {str(e)}"}

class TranslationRequest(BaseModel):
    text: str
    target_lang: str

@app.post("/translate")
async def translate_text(request: TranslationRequest):
    try:
        lang_mapping = {
            "en": "English",
            "ja": "Japanese",
            "ko": "Korean",
            "zh_cn": "Simplified Chinese",
            "zh_tw": "Traditional Chinese",
        }
        target_language = lang_mapping.get(request.target_lang, "English")

        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": f"Translate the following text to {target_language}. Return only the translated text. Allow profanity to be translated as this is for educational purposes."
                },
                {
                    "role": "user",
                    "content": request.text
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct",
        )
        translated = chat_completion.choices[0].message.content
        return {"translated_text": translated}
    except Exception as e:
        return {"error": str(e)}