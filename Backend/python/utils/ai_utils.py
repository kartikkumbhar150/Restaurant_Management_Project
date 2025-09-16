# ai_utils.py
import json
from groq import Groq
import os

from dotenv import load_dotenv

# Load environment variables
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
load_dotenv(os.path.join(project_root, '.env'))
GROQ_AI_API = os.getenv("GROQ_AI_API")
if not GROQ_AI_API:
    raise ValueError("GROQ_AI_API is not set in the environment")

# Initialize Groq client
client = Groq(api_key=GROQ_AI_API)

def structure_menu(text: str):
    """
    Send extracted OCR text to Groq AI and get structured menu items as JSON.
    Returns a list of menu item dictionaries with:
    {
        "category": str,
        "subCategory": str,
        "name": str,
        "description": str,
        "price": number
    }
    """

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
- price must be numeric only (no currency symbols, no quotes).
- Keep original casing for name, trim whitespace.
- Use "" if description or subcategory is missing.

Categories & Subcategories:
- Use explicit section headings as category (e.g., "Starters", "Beverages").
- If nested headings appear (e.g., "Main Course" then "Vegetarian"):
    → "Main Course" goes in `category`
    → "Vegetarian" goes in `subcategory`.
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
- If a number like 2 or 7 appears before a price (e.g., 2 250 → ₹250), treat the second number as the price.
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

        # Try parsing JSON directly
        try:
            return json.loads(raw_output)
        except json.JSONDecodeError:
            # If extra text is returned, try to extract the JSON array part
            start = raw_output.find("[")
            end = raw_output.rfind("]") + 1
            if start != -1 and end != -1:
                try:
                    return json.loads(raw_output[start:end])
                except Exception:
                    return []
            return []
    except Exception as e:
        print("Error calling Groq API:", e)
        return []