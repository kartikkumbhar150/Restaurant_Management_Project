import sys
import os
import json
import pytesseract
from PIL import Image
from groq import Groq
import re

from dotenv import load_dotenv

# Load environment variables
load_dotenv()
GROQ_AI_API = os.getenv("GROQ_AI_API")
if not GROQ_AI_API:
    raise ValueError("GROQ_AI_API is not set in the environment")

# Initialize Groq client
client = Groq(api_key=GROQ_AI_API)

def clean_rupee_misreads(text):
    """
    Clean OCR misreads related to currency symbols or stray digits before price.
    """
    # Remove ₹, Rs, INR, $ symbols
    text = re.sub(r"(₹|\b[27]|Rs\.?|INR|\$)\s*", "", text)
    # Merge digits separated by spaces (e.g., '2 5 0' → '250')
    text = re.sub(r"(\d)\s+(\d)", r"\1\2", text)
    return text

def extract_text(image_path):
    """Extract raw text from the image using Tesseract OCR and clean it."""
    try:
        text = pytesseract.image_to_string(Image.open(image_path))
        text = text.encode("utf-8", "ignore").decode()
        text = clean_rupee_misreads(text)
        return text
    except Exception as e:
        error_output = {"status": "failure", "message": f"OCR extraction error: {e}", "data": None}
        print(json.dumps(error_output, indent=2, ensure_ascii=False))
        sys.exit(1)

def extract_json_array(text):
    """Safely extract the first JSON array from a string."""
    match = re.search(r"\[.*\]", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except:
            return []
    return []

def parse_price(price_str):
    """Extract first numeric value from price string."""
    nums = re.findall(r"\d+", str(price_str))
    return int(nums[0]) if nums else 0

def structure_menu(text):
    """Send extracted text to Groq AI and get structured menu items as JSON."""
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
- If no items found, return [].
- All objects must include all five fields.
- price must be numeric only.
- Keep original casing for name, trim whitespace.
- Use "" if description or subcategory is missing.

Categories & Subcategories:
- Use explicit section headings as category.
- If nested headings appear, category → category, subcategory → subCategory.
- If no subcategory exists, use "".
- If no category is found, use "Uncategorized".
- Ignore non-menu text like “Welcome”, “Contact”, “About Us”.

Item Detection:
- Items may appear in formats such as:
  • Name – Description ₹250
  • Name ₹250
  • Name (line 1), Description (line 2), Price (line 3)
  • Table rows: | Name | Description | ₹250 |
  • Bullets: • Item Name – Description 300
- Merge consecutive lines until a new item, heading, or blank line.

Prices:
- Extract only the main numeric price.
- Ignore ₹, Rs, INR, $, etc.
- If a number like 2 or 7 appears before a price (e.g., 2 250 → 250), treat the second number as the price.
- If multiple prices exist (e.g., small/large), pick the first numeric price.

Descriptions:
- Extract text after separators (–, —, :, parentheses).
- If none present, use "".

Final Requirement:
Return a single JSON array of all menu items following the schema.
Do not output explanations, comments, or extra keys.

Text:
{text}
"""

    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": "You are a restaurant menu extraction assistant."},
                {"role": "system", "content": "Always return valid JSON array only, nothing else."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2
        )

        raw_output = response.choices[0].message.content.strip()
        menu_items = extract_json_array(raw_output)

        # Ensure price is numeric
        for item in menu_items:
            item["price"] = parse_price(item.get("price", 0))
        return menu_items

    except Exception as e:
        error_output = {"status": "failure", "message": f"Groq API error: {e}", "data": None}
        print(json.dumps(error_output, indent=2, ensure_ascii=False))
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        error_output = {"status": "failure", "message": "Usage: python script.py <image_path>", "data": None}
        print(json.dumps(error_output, indent=2, ensure_ascii=False))
        sys.exit(1)

    image_path = sys.argv[1]
    raw_text = extract_text(image_path)
    menu_data = structure_menu(raw_text)

    print(json.dumps(menu_data, indent=2, ensure_ascii=False))