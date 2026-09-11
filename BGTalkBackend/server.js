import express from "express";
import { TranslationServiceClient } from "@google-cloud/translate";

const app = express();
app.use(express.json({ limit: "64kb" }));

const port = Number(process.env.PORT || 8080);
const client = new TranslationServiceClient();

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "BGTalk translation backend" });
});

app.post("/translate", async (req, res) => {
  const { text, sourceLanguage, targetLanguage } = req.body ?? {};

  if (typeof text !== "string" || !text.trim()) {
    return res.status(400).json({ error: "text is required" });
  }
  if (!["bg", "en", "es"].includes(sourceLanguage) || !["bg", "en", "es"].includes(targetLanguage)) {
    return res.status(400).json({ error: "Unsupported language" });
  }
  if (sourceLanguage === targetLanguage) {
    return res.json({ translatedText: text });
  }

  try {
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

    const translatedText = response.translations?.[0]?.translatedText?.trim();
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
