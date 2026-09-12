package com.kiddbg.bgtalk

import android.content.Context
import android.content.Intent
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import java.util.Locale

class SpeechManager(context: Context) {
    private val appContext = context.applicationContext
    private var recognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null

    fun startListening(
        language: AppLanguage,
        onResult: (String) -> Unit,
        onError: (String) -> Unit,
        onPartialResult: ((String) -> Unit)? = null,
        onListeningStateChanged: ((Boolean) -> Unit)? = null
    ) {
        stopListening()
        if (!SpeechRecognizer.isRecognitionAvailable(appContext)) {
            onError("Speech recognition is not available on this device")
            return
        }
        recognizer = SpeechRecognizer.createSpeechRecognizer(appContext).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onResults(results: android.os.Bundle?) {
                    onListeningStateChanged?.invoke(false)
                    val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (!text.isNullOrBlank()) onResult(text) else onError("No speech detected")
                    destroyRecognizer()
                }
                override fun onPartialResults(partialResults: android.os.Bundle?) {
                    val text = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (!text.isNullOrBlank()) onPartialResult?.invoke(text)
                }
                override fun onError(error: Int) {
                    onListeningStateChanged?.invoke(false)
                    onError(readableSpeechError(error))
                    destroyRecognizer()
                }
                override fun onReadyForSpeech(params: android.os.Bundle?) = Unit
                override fun onBeginningOfSpeech() = Unit
                override fun onRmsChanged(rmsdB: Float) = Unit
                override fun onBufferReceived(buffer: ByteArray?) = Unit
                override fun onEndOfSpeech() = Unit
                override fun onEvent(eventType: Int, params: android.os.Bundle?) = Unit
            })
            startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, language.localeTag)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            })
        }
        onListeningStateChanged?.invoke(true)
    }

    fun stopListening() {
        recognizer?.stopListening()
        destroyRecognizer()
    }

    fun speak(text: String, language: AppLanguage) {
        if (text.isBlank()) return
        if (textToSpeech == null) {
            textToSpeech = TextToSpeech(appContext) { status ->
                if (status == TextToSpeech.SUCCESS) speakNow(text, language)
            }
        } else {
            speakNow(text, language)
        }
    }

    fun stopSpeaking() {
        textToSpeech?.stop()
    }

    private fun speakNow(text: String, language: AppLanguage) {
        val locale = Locale.forLanguageTag(language.localeTag)
        val result = textToSpeech?.setLanguage(locale)
        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) return
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "BGTalkTranslation")
    }

    private fun destroyRecognizer() {
        recognizer?.destroy()
        recognizer = null
    }

    private fun readableSpeechError(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_AUDIO -> "Microphone audio error"
        SpeechRecognizer.ERROR_CLIENT -> "Speech recognition client error"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission is required"
        SpeechRecognizer.ERROR_NETWORK -> "Speech recognition network error"
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Speech recognition timed out"
        SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Speech recognition is busy"
        SpeechRecognizer.ERROR_SERVER -> "Speech recognition server error"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected in time"
        else -> "Speech recognition error"
    }

    fun release() {
        stopListening()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }
}
