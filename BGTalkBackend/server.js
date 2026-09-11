import express from "express";

const app = express();
app.use(express.json({ limit: "64kb" }));

const port = Number(process.env.PORT || 8080);
const supportedLanguages = new Set(["bg", "en", "es"]);

function providerConfigured() {
  return Boolean(process.env.DEEPL_API_KEY);
}

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "BGTalk translation backend",
    providerConfigured: providerConfigured(),
    provider: providerConfigured() ? "deepl" : "none",
  });
});

async function translateWithDeepL(text, sourceLanguage, targetLanguage, apiKey) {
  const response = await fetch("https://api-free.deepl.com/v2/translate", {
    method: "POST",
    headers: {
      "Authorization": `DeepL-Auth-Key ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      text: [text],
      source_lang: sourceLanguage.toUpperCase(),
      target_lang: targetLanguage.toUpperCase(),
    }),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new Error(`DeepL API returned HTTP ${response.status}: ${detail}`);
  }

  const data = await response.json();
  return data?.translations?.[0]?.text?.trim() || "";
}

app.post("/translate", async (req, res) => {
  const { text, sourceLanguage, targetLanguage } = req.body ?? {};

  if (typeof text !== "string" || !text.trim() || text.length > 5000) {
    return res.status(400).json({ error: "text must be between 1 and 5000 characters" });
  }

  if (!supportedLanguages.has(sourceLanguage) || !supportedLanguages.has(targetLanguage)) {
    return res.status(400).json({ error: "Unsupported language" });
  }

  if (sourceLanguage === targetLanguage) {
    return res.json({ translatedText: text });
  }

  const apiKey = process.env.DEEPL_API_KEY;
  if (!apiKey) {
    return res.status(503).json({ error: "Translation provider is not configured" });
  }

  try {
    const translatedText = await translateWithDeepL(
      text,
      sourceLanguage,
      targetLanguage,
      apiKey,
    );

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
