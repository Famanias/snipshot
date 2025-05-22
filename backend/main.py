from fastapi import FastAPI, UploadFile, File # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import cv2 # type: ignore
import easyocr # type: ignore
from langdetect import detect # type: ignore
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast
import numpy as np # type: ignore

app = FastAPI()

# Allow CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize EasyOCR and mBART
reader = easyocr.Reader(['ja', 'ko', 'en', 'ch_sim'], gpu=True)  # Use GPU if available
model = MBartForConditionalGeneration.from_pretrained("facebook/mbart-large-50-many-to-many-mmt")
tokenizer = MBart50TokenizerFast.from_pretrained("facebook/mbart-large-50-many-to-many-mmt")

@app.post("/preprocess")
async def preprocess_image(file: UploadFile = File(...)):
    image = await file.read()
    image = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    denoised = cv2.fastNlMeansDenoising(binary)
    _, encoded_image = cv2.imencode(".png", denoised)
    return {"image": encoded_image.tobytes().hex()}

@app.post("/ocr")
async def extract_text(file: UploadFile = File(...)):
    image = await file.read()
    image = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    results = reader.readtext(image, detail=0)  # Extract text only
    text = " ".join(results)
    language = detect(text) if text.strip() else "unknown"
    return {"text": text, "language": language}

@app.post("/translate")
async def translate_text(text: str, target_lang: str):
    tokenizer.src_lang = "ja_XX" if detect(text) == "ja" else "ko_KR" if detect(text) == "ko" else "ch_SIM" if detect(text) == "ch_sim" else "ch_TRA" if detect(text) == "ch_tra" else "en_XX"
    encoded = tokenizer(text, return_tensors="pt")
    generated_tokens = model.generate(**encoded, forced_bos_token_id=tokenizer.lang_code_to_id[target_lang])
    translated = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
    return {"translated_text": translated}

# Run: uvicorn main:app --reload