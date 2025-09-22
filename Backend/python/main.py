import sys
import os
import json
import pytesseract
from PIL import Image
from groq import Groq
import re
from dotenv import load_dotenv

# ------------------ Setup ------------------
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
load_dotenv(os.path.join(project_root, '.env'))

# Load environment variables
GROQ_AI_API = os.getenv("GROQ_AI_API")
GROQ_AI_MODEL = os.getenv("GROQ_AI_MODEL")
if not GROQ_AI_API:
    raise ValueError("GROQ_AI_API is not set in the environment")

# Initialize Groq client
client = Groq(api_key=GROQ_AI_API)

# ------------------ Helpers ------------------
def clean_rupee_misreads(text: str) -> str:
    """Clean OCR misreads related to currency symbols or stray digits before price."""
    text = re.sub(r"(₹|Rs\.?|INR|\$)\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"(\d)\s+(\d)", r"\1\2", text)  # merge spaced digits
    return text


def extract_text(image_path: str) -> str:
    """Extract raw text from the image using Tesseract OCR and clean it."""
    custom_config = r'--oem 3 --psm 6'
    text = pytesseract.image_to_string(Image.open(image_path), config=custom_config)
    text = text.encode("utf-8", "ignore").decode()
    text = clean_rupee_misreads(text)
    return text


def safe_json_loads(raw: str):
    """Try to parse JSON directly, fallback to extracting first array."""
    try:
        return json.loads(raw)
    except Exception:
        match = re.search(r"\[.*\]", raw, re.DOTALL)
        if match:
            try:
                return json.loads(match.group())
            except Exception:
                return []
    return []


def parse_price(price_str):
    """Extract first numeric value (int or float) from price string."""
    nums = re.findall(r"\d+(?:\.\d+)?", str(price_str))
    if not nums:
        return 0
    return float(nums[0]) if "." in nums[0] else int(nums[0])


# ------------------ Main LLM Function ------------------
def structure_menu(text: str):
    """
    Send extracted text to Groq AI and get structured menu items as JSON.
    Handles subcategories (Veg/Chicken/Mixed) and descriptions (Half/Full/6 Pc).
    """
    if not text.strip():
        return []

    prompt = f"""
Extract menu items from the following text and return them as a JSON array.

Schema:
[
  {{
    "category": "string",
    "subCategory": "string",
    "name": "string",
    "description": "string",
    "price": number
  }}
]

Rules:
- Output valid JSON only, no extra text.
- Always return an array.
- Each object must include: category, subCategory, name, description, price.
- "subCategory":
   * If the item has options like Veg/Chicken/Mixed, use these as subCategory.
   * If no subCategory is found, set subCategory = "".
- "description":
   * Put portion details like "Half", "Full", "6 Pc", "8 Pc", "Portion" here.
   * If no description available, set description = "".
- category = section headings (like "SOUP", "NOODLES", etc.).
- price must be numeric only (int).
- Ignore unrelated text (welcome, contact, etc.).

Examples:
Input: "Hakka Noodles Veg 110, Chicken 130, Mixed 150"
Output:
[
  {{"category":"NOODLES","subCategory":"Veg","name":"Hakka Noodles","description":"","price":110}},
  {{"category":"NOODLES","subCategory":"Chicken","name":"Hakka Noodles","description":"","price":130}},
  {{"category":"NOODLES","subCategory":"Mixed","name":"Hakka Noodles","description":"","price":150}}
]

Input: "Butter Chicken (Half 200 / Full 350)"
Output:
[
  {{"category":"MAIN COURSE","subCategory":"","name":"Butter Chicken","description":"Half","price":200}},
  {{"category":"MAIN COURSE","subCategory":"","name":"Butter Chicken","description":"Full","price":350}}
]

Input: "Chicken Drums of Heaven (6Pc 200)"
Output:
[
  {{"category":"CHICKEN DRY","subCategory":"","name":"Chicken Drums of Heaven","description":"6 Pc","price":200}}
]

Text:
{text}
"""

    try:
        response = client.chat.completions.create(
            model=GROQ_AI_MODEL,
            messages=[
                {"role": "system", "content": "You are a restaurant menu extraction assistant."},
                {"role": "system", "content": "Always return valid JSON array only, nothing else."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2
        )

        raw_output = response.choices[0].message.content.strip()
        menu_items = safe_json_loads(raw_output)

        # Normalize prices
        for item in menu_items:
            item["price"] = parse_price(item.get("price", 0))

        return menu_items

    except Exception as e:
        print(json.dumps({"status": "failure", "message": f"Groq API error: {e}", "data": None}, indent=2))
        sys.exit(1)


# ------------------ CLI Entry ------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"status": "failure", "message": "Usage: python script.py <image_path>", "data": None}, indent=2))
        sys.exit(1)

    image_path = sys.argv[1]
    raw_text = extract_text(image_path)
    menu_data = structure_menu(raw_text)

    print(json.dumps(menu_data, indent=2, ensure_ascii=False))
