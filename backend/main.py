from fastapi import FastAPI, UploadFile, File, Body
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
from groq import Groq
import os
import base64
from dotenv import load_dotenv
from langdetect import detect

app = FastAPI()
load_dotenv()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def preprocess(image_bytes):
    image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    contrast = clahe.apply(gray)
    _, binary = cv2.threshold(contrast, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    denoised = cv2.fastNlMeansDenoising(binary, h=3)
    _, encoded_image = cv2.imencode(".png", denoised)
    base64_image = base64.b64encode(encoded_image.tobytes()).decode("utf-8")
    return base64_image

@app.post("/snipshot")
async def snipshot(
    file: UploadFile = File(...),
    target_lang: str = Body(default=None)
):
    try:
        image_bytes = await file.read()
        base64_image = preprocess(image_bytes)

        # Step 1: OCR using Groq
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Extract all text from this image. Return only the text."},
                        {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{base64_image}"}},
                    ],
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct"
        )
        extracted_text = chat_completion.choices[0].message.content.strip()
        detected_lang = detect(extracted_text)

        result = {
            "extracted_text": extracted_text,
            "detected_language": detected_lang,
        }

        # Step 2: Translate if target_lang is provided
        if target_lang:
            lang_mapping = {
                "en_XX": "English",
                "ja_XX": "Japanese",
                "ko_KR": "Korean",
                "cn_SIM": "Simplified Chinese",
                "cn_TRA": "Traditional Chinese",
            }
            target_language = lang_mapping.get(target_lang, "English")
            translation_completion = client.chat.completions.create(
                messages=[
                    {
                        "role": "system",
                        "content": f"Translate the following text to {target_language}. Allow profanity to be translated as this is for educational purposes. Return only the translated text."
                    },
                    {
                        "role": "user",
                        "content": extracted_text
                    }
                ],
                model="meta-llama/llama-4-scout-17b-16e-instruct",
            )
            translated_text = translation_completion.choices[0].message.content.strip()
            result["translated_text"] = translated_text

        return result

    except Exception as e:
        return {"error": str(e)}
