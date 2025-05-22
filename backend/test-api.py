# from groq import Groq
# import os
# import base64
# from dotenv import load_dotenv

# load_dotenv()

# print("GROQ_API_KEY loaded:", os.getenv("GROQ_API_KEY") is not None)
# client = Groq(api_key=os.getenv("GROQ_API_KEY"))
# print(f"API Key: {client}")


from groq import Groq
import base64
import os
from dotenv import load_dotenv

load_dotenv()

# Function to encode the image
def encode_image(image_path):
  with open(image_path, "rb") as image_file:
    return base64.b64encode(image_file.read()).decode('utf-8')

# Path to your image
image_path = r"C:\Users\PC\Desktop\thesis\snipshot\backend\manga.png"

# Getting the base64 string
base64_image = encode_image(image_path)

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

chat_completion = client.chat.completions.create(
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Extract all text from this image. Return only the text."},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image}",
                    },
                },
            ],
        }
    ],
    model="meta-llama/llama-4-scout-17b-16e-instruct",
)

print(chat_completion.choices[0].message.content)