from fastapi import FastAPI, UploadFile, File # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import cv2 # type: ignore
import easyocr # type: ignore
from langdetect import detect # type: ignore
from transformers import MBartForConditionalGeneration, MBart50TokenizerFast
import numpy as np # type: ignore
from functools import lru_cache

app = FastAPI()

# Allow CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize readers with proper language groupings
@lru_cache(maxsize=2)
def get_reader(langs):
    return easyocr.Reader(langs, gpu=True)

# Supported language groups
READERS = {
    'east_asian': ['ja', 'ko', 'en'],  # Japanese, Korean with English
    'chinese': ['ch_sim', 'en']        # Chinese with English
}


# Initialize mBART model
model = MBartForConditionalGeneration.from_pretrained("facebook/mbart-large-50-many-to-many-mmt")
tokenizer = MBart50TokenizerFast.from_pretrained("facebook/mbart-large-50-many-to-many-mmt")

@app.post("/preprocess")
async def preprocess_image(file: UploadFile = File(...)):
    """Preprocess image for better OCR results"""
    image = await file.read()
    image = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    denoised = cv2.fastNlMeansDenoising(binary)
    _, encoded_image = cv2.imencode(".png", denoised)
    return {"image": encoded_image.tobytes().hex()}

@app.post("/ocr")
async def extract_text(file: UploadFile = File(...)):
    """Extract text from image with language detection"""
    image = await file.read()
    image = cv2.imdecode(np.frombuffer(image, np.uint8), cv2.IMREAD_COLOR)
    
    # Try East Asian languages first
    try:
        reader = get_reader(tuple(READERS['east_asian']))
        results = reader.readtext(image, detail=0)
        text = " ".join(results)
        if text.strip():
            return {"text": text, "language": detect(text)}
    except Exception as e:
        print(f"East Asian OCR failed: {e}")
    
    # Fall back to Chinese
    try:
        reader = get_reader(tuple(READERS['chinese']))
        results = reader.readtext(image, detail=0)
        text = " ".join(results)
        return {
            "text": text,
            "language": detect(text) if text.strip() else "unknown"
        }
    except Exception as e:
        return {"error": str(e)}
    
@app.post("/translate")

async def translate_text(text: str, target_lang: str):
    """Translate text to target language"""
    try:
        detected_lang = detect(text)
        lang_mapping = {
            "ja": "ja_XX",
            "ko": "ko_KR",
            "zh-cn": "zh_CN",
            "en": "en_XX"
        }
        
        tokenizer.src_lang = lang_mapping.get(detected_lang, "en_XX")
        encoded = tokenizer(text, return_tensors="pt")
        generated_tokens = model.generate(
            **encoded,
            forced_bos_token_id=tokenizer.lang_code_to_id[target_lang]
        )
        translated = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
        return {"translated_text": translated}
    except Exception as e:
        return {"error": str(e)}

# Run with: uvicorn main:app --reload