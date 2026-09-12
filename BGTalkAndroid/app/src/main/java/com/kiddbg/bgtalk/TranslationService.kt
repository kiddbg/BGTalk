package com.kiddbg.bgtalk

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class TranslationService {
    private val endpoint = "https://bgtalk-backend-production.up.railway.app/translate"
    private val maxAttempts = 2

    suspend fun translate(text: String, source: AppLanguage, target: AppLanguage): String = withContext(Dispatchers.IO) {
        require(text.isNotBlank()) { "Text cannot be empty" }

        var lastError: Exception? = null
        repeat(maxAttempts) { attempt ->
            try {
                return@withContext requestTranslation(text, source, target)
            } catch (error: Exception) {
                lastError = error
                if (attempt < maxAttempts - 1) delay(350L)
            }
        }

        throw lastError ?: IllegalStateException("Translation failed")
    }

    private fun requestTranslation(text: String, source: AppLanguage, target: AppLanguage): String {
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
            val responseBody = if (connection.responseCode in 200..299) {
                connection.inputStream.bufferedReader().use { it.readText() }
            } else {
                connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
            }

            if (connection.responseCode !in 200..299) {
                val serverError = runCatching { JSONObject(responseBody).optString("error") }.getOrNull()
                throw IllegalStateException(
                    serverError?.takeIf { it.isNotBlank() }
                        ?: "Translation server error: ${connection.responseCode}"
                )
            }

            val translated = JSONObject(responseBody).optString("translatedText").trim()
            if (translated.isEmpty()) throw IllegalStateException("Empty translation")
            return translated
        } finally {
            connection.disconnect()
        }
    }
}
