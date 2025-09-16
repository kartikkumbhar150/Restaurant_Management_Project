import pytesseract
from PIL import Image
import re
import json
import sys

def clean_rupee_misreads(text: str) -> str:
    """
    Clean OCR misreads related to currency symbols or stray digits before price.
    """
    text = re.sub(r"(₹|\b[27]|Rs\.?|INR|\$)\s*", "", text)  # remove currency symbols
    text = re.sub(r"(\d)\s+(\d)", r"\1\2", text)  # merge spaced digits like '2 5 0' → '250'
    return text

def extract_text(image_path: str) -> str:
    """Extract raw text from the image using Tesseract OCR and clean it."""
    try:
        text = pytesseract.image_to_string(Image.open(image_path))
        text = text.encode("utf-8", "ignore").decode()
        return clean_rupee_misreads(text)
    except Exception as e:
        error_output = {
            "status": "failure",
            "message": f"OCR extraction error: {e}",
            "data": None
        }
        print(json.dumps(error_output, indent=2, ensure_ascii=False))
        sys.exit(1)
