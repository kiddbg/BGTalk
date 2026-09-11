import express from "express";
import { TranslationServiceClient } from "@google-cloud/translate";

const app = express();
app.use(express.json({ limit: "64kb" }));

const port = Number(process.env.PORT || 8080);
const client = new TranslationServiceClient();

function providerConfigured() {
  return Boolean(process.env.GOOGLE_TRANSLATE_API_KEY || process.env.GOOGLE_CLOUD_PROJECT);
}

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "BGTalk translation backend",
    providerConfigured: providerConfigured(),
    provider: process.env.GOOGLE_TRANSLATE_API_KEY ? "google-api-key" : "google-cloud",
  });
});

async function translateWithApiKey(text, sourceLanguage, targetLanguage, apiKey) {
  const url = "https://translation.googleapis.com/language/translate/v2";
  const response = await fetch(`${url}?key=${encodeURIComponent(apiKey)}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      q: text,
      source: sourceLanguage,
      target: targetLanguage,
      format: "text",
    }),
  });

  if (!response.ok) {
    throw new Error(`Google API returned HTTP ${response.status}`);
  }

  const data = await response.json();
  return data?.data?.translations?.[0]?.translatedText?.trim() || "";
}

app.post("/translate", async (req, res) => {
  const { text, sourceLanguage, targetLanguage } = req.body ?? {};

  if (typeof text !== "string" || !text.trim() || text.length > 5000) {
    return res.status(400).json({ error: "text must be between 1 and 5000 characters" });
  }
  if (!["bg", "en", "es"].includes(sourceLanguage) || !["bg", "en", "es"].includes(targetLanguage)) {
    return res.status(400).json({ error: "Unsupported language" });
  }
  if (sourceLanguage === targetLanguage) {
    return res.json({ translatedText: text });
  }

  try {
    const apiKey = process.env.GOOGLE_TRANSLATE_API_KEY;
    let translatedText = "";

    if (apiKey) {
      translatedText = await translateWithApiKey(text, sourceLanguage, targetLanguage, apiKey);
    } else {
      const projectId = process.env.GOOGLE_CLOUD_PROJECT;
      if (!projectId) {
        return res.status(503).json({ error: "Translation provider is not configured" });
      }

      const parent = `projects/${projectId}/locations/global`;
      const [response] = await client.translateText({
        parent,
        contents: [text],
        mimeType: "text/plain",
        sourceLanguageCode: sourceLanguage,
        targetLanguageCode: targetLanguage,
      });

      translatedText = response.translations?.[0]?.translatedText?.trim() || "";
    }

    if (!translatedText) {
      return res.status(502).json({ error: "Translation provider returned no text" });
    }

    return res.json({ translatedText });
  } catch (error) {
    console.error("Translation request failed", error);
    return res.status(502).json({ error: "Translation provider request failed" });
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`BGTalk backend listening on ${port}`);
});
