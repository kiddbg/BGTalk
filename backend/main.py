import os
from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="BGTalk Translation Backend", version="0.1.0")

Language = Literal["bg", "en", "es"]


class TranslationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    sourceLanguage: Language
    targetLanguage: Language


class TranslationResponse(BaseModel):
    translatedText: str


@app.get("/health")
async def health():
    return {"status": "ok", "providerConfigured": bool(os.getenv("TRANSLATION_API_URL"))}


@app.post("/translate", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    if request.sourceLanguage == request.targetLanguage:
        return TranslationResponse(translatedText=request.text)

    api_url = os.getenv("TRANSLATION_API_URL")
    api_key = os.getenv("TRANSLATION_API_KEY")

    if not api_url or not api_key:
        raise HTTPException(status_code=503, detail="Translation provider is not configured")

    payload = {
        "text": request.text,
        "sourceLanguage": request.sourceLanguage,
        "targetLanguage": request.targetLanguage,
    }
    headers = {"Authorization": f"Bearer {api_key}"}

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(api_url, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(status_code=502, detail="Translation provider request failed") from exc

    translated_text = data.get("translatedText")
    if not isinstance(translated_text, str) or not translated_text.strip():
        raise HTTPException(status_code=502, detail="Translation provider returned an invalid response")

    return TranslationResponse(translatedText=translated_text)
