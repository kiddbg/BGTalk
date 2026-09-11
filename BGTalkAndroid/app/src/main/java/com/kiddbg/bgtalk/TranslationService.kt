package com.kiddbg.bgtalk

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class TranslationService {
    private val endpoint = "https://bgtalk-backend-production.up.railway.app/translate"

    suspend fun translate(text: String, source: AppLanguage, target: AppLanguage): String = withContext(Dispatchers.IO) {
        require(text.isNotBlank()) { "Text cannot be empty" }

        val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 15_000
            readTimeout = 15_000
            doOutput = true
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Accept", "application/json")
        }

        try {
            val body = JSONObject().apply {
                put("text", text)
                put("sourceLanguage", source.code)
                put("targetLanguage", target.code)
            }.toString()

            connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            if (connection.responseCode !in 200..299) {
                throw IllegalStateException("Translation server error: ${connection.responseCode}")
            }

            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val translated = JSONObject(response).optString("translatedText").trim()
            if (translated.isEmpty()) throw IllegalStateException("Empty translation")
            translated
        } finally {
            connection.disconnect()
        }
    }
}
