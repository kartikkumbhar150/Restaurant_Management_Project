import uvicorn
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
from utils.ocr_utils import extract_text
from utils.ai_utils import structure_menu

app = FastAPI(title="Menu Extraction API", version="1.0")

# Allow frontend requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with ["http://localhost:3000"] for security
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/extract-menu")
async def extract_menu(file: UploadFile = File(...)):
    try:
        # Save uploaded file temporarily
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Step 1: OCR extraction
        raw_text = extract_text(file_path)

        # Step 2: Groq AI structuring
        menu_data = structure_menu(raw_text)

        return JSONResponse(content={"status": "success", "data": menu_data})

    except Exception as e:
        return JSONResponse(
            content={"status": "failure", "message": str(e)},
            status_code=500
        )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
