# ocr_utils.py
import pytesseract
from PIL import Image

def extract_text(image_path: str) -> str:
    """
    Extract raw text from an image using Tesseract OCR.
    :param image_path: Path to the image file.
    :return: Extracted text as a string.
    """
    return pytesseract.image_to_string(Image.open(image_path))