import os
from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="BGTalk Translation Backend", version="0.2.0")

Language = Literal["bg", "en", "es"]


class TranslationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=5000)
    sourceLanguage: Language
    targetLanguage: Language


class TranslationResponse(BaseModel):
    translatedText: str


def provider_configured() -> bool:
    # Google Cloud Translation is the preferred production provider. The generic
    # provider remains supported for future provider swaps.
    return bool(os.getenv("GOOGLE_TRANSLATE_API_KEY")) or bool(
        os.getenv("TRANSLATION_API_URL") and os.getenv("TRANSLATION_API_KEY")
    )


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "providerConfigured": provider_configured(),
        "provider": "google" if os.getenv("GOOGLE_TRANSLATE_API_KEY") else "generic",
    }


async def translate_with_google(request: TranslationRequest, api_key: str) -> str:
    url = "https://translation.googleapis.com/language/translate/v2"
    payload = {
        "q": request.text,
        "source": request.sourceLanguage,
        "target": request.targetLanguage,
        "format": "text",
    }

    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(url, params={"key": api_key}, json=payload)
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(status_code=502, detail="Google translation request failed") from exc

    try:
        translated_text = data["data"]["translations"][0]["translatedText"]
    except (KeyError, IndexError, TypeError) as exc:
        raise HTTPException(status_code=502, detail="Google translation returned an invalid response") from exc

    if not isinstance(translated_text, str) or not translated_text.strip():
        raise HTTPException(status_code=502, detail="Google translation returned no translated text")

    return translated_text


async def translate_with_generic_provider(request: TranslationRequest, api_url: str, api_key: str) -> str:
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

    return translated_text


@app.post("/translate", response_model=TranslationResponse)
async def translate(request: TranslationRequest):
    if request.sourceLanguage == request.targetLanguage:
        return TranslationResponse(translatedText=request.text)

    google_key = os.getenv("GOOGLE_TRANSLATE_API_KEY")
    if google_key:
        translated_text = await translate_with_google(request, google_key)
        return TranslationResponse(translatedText=translated_text)

    api_url = os.getenv("TRANSLATION_API_URL")
    api_key = os.getenv("TRANSLATION_API_KEY")
    if api_url and api_key:
        translated_text = await translate_with_generic_provider(request, api_url, api_key)
        return TranslationResponse(translatedText=translated_text)

    raise HTTPException(status_code=503, detail="Translation provider is not configured")
