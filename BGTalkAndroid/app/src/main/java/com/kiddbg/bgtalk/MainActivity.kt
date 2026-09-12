package com.kiddbg.bgtalk

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val requestAudio = registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestAudio.launch(Manifest.permission.RECORD_AUDIO)
        }
        setContent { BGTalkScreen() }
    }
}

@Composable
private fun BGTalkScreen() {
    var source by rememberSaveable { mutableStateOf(AppLanguage.ENGLISH) }
    var target by rememberSaveable { mutableStateOf(AppLanguage.BULGARIAN) }
    var text by rememberSaveable { mutableStateOf("") }
    var translation by rememberSaveable { mutableStateOf("") }
    var status by rememberSaveable { mutableStateOf("") }
    var conversationMode by rememberSaveable { mutableStateOf(false) }
    var historyMode by rememberSaveable { mutableStateOf(false) }
    var listeningSpeaker by remember { mutableStateOf<Int?>(null) }
    val scope = rememberCoroutineScope()
    val service = remember { TranslationService() }
    val context = LocalContext.current
    val speech = remember(context) { SpeechManager(context) }
    val historyStore = remember(context) { ConversationHistoryStore(context) }
    val messages = remember { mutableStateOf(listOf<ConversationMessage>()) }
    var partialTranslationJob by remember { mutableStateOf<Job?>(null) }

    DisposableEffect(Unit) {
        onDispose {
            partialTranslationJob?.cancel()
            speech.release()
        }
    }

    MaterialTheme {
        when {
            historyMode -> HistoryScreen(
                messages = historyStore.load(),
                onBack = { historyMode = false },
                onClear = { historyStore.clear(); historyMode = false }
            )
            conversationMode -> ConversationScreen(
                source = source,
                target = target,
                messages = messages.value,
                listeningSpeaker = listeningSpeaker,
                onBack = { speech.stopListening(); listeningSpeaker = null; conversationMode = false },
                onSwap = { if (listeningSpeaker == null) { val old = source; source = target; target = old } },
                onClear = { messages.value = emptyList(); historyStore.clear(); status = "" },
                onStop = { speech.stopListening(); listeningSpeaker = null; status = "" },
                onSpeak = { speaker, language, otherLanguage ->
                    speech.startListening(
                        language,
                        { recognized ->
                            if (recognized.isBlank()) return@startListening
                            scope.launch {
                                try {
                                    status = "Translating…"
                                    val translated = service.translate(recognized, language, otherLanguage)
                                    val updated = messages.value + ConversationMessage(speaker, recognized, translated, language, otherLanguage)
                                    messages.value = updated
                                    historyStore.save(updated)
                                    status = ""
                                    speech.speak(translated, otherLanguage)
                                } catch (error: Exception) {
                                    status = error.message ?: "Translation failed"
                                }
                            }
                        },
                        { error -> listeningSpeaker = null; status = error },
                        onListeningStateChanged = { listening -> listeningSpeaker = if (listening) speaker else null }
                    )
                },
                status = status
            )
            else -> {
                Column(Modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.Top) {
                    Text("BGTalk", style = MaterialTheme.typography.headlineLarge)
                    Text("Bulgarian • English • Spanish", style = MaterialTheme.typography.bodyMedium)
                    Spacer(Modifier.height(20.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(onClick = { source = nextLanguage(source) }, modifier = Modifier.weight(1f)) { Text(source.displayName) }
                        Button(onClick = { val old = source; source = target; target = old }) { Text("⇄") }
                        OutlinedButton(onClick = { target = nextLanguage(target) }, modifier = Modifier.weight(1f)) { Text(target.displayName) }
                    }
                    Spacer(Modifier.height(16.dp))
                    OutlinedTextField(text, { text = it }, Modifier.fillMaxWidth(), label = { Text("Speak or type") }, minLines = 4)
                    Spacer(Modifier.height(12.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = {
                            status = "Listening…"
                            speech.startListening(
                                source,
                                { result ->
                                    text = result
                                    status = ""
                                    partialTranslationJob?.cancel()
                                    partialTranslationJob = null
                                    scope.launch {
                                        try { translation = service.translate(result, source, target) }
                                        catch (_: Exception) { }
                                    }
                                },
                                { error -> status = error },
                                { partial ->
                                    text = partial
                                    status = "Translating…"
                                    partialTranslationJob?.cancel()
                                    partialTranslationJob = scope.launch {
                                        delay(500)
                                        try {
                                            translation = service.translate(partial, source, target)
                                            status = "Listening…"
                                        } catch (_: Exception) { }
                                    }
                                }
                            )
                        }, modifier = Modifier.weight(1f)) { Text("🎙 Speak") }
                        Button(onClick = { scope.launch { status = "Translating…"; try { translation = service.translate(text, source, target); status = "" } catch (error: Exception) { status = error.message ?: "Translation failed" } } }, enabled = text.isNotBlank(), modifier = Modifier.weight(1f)) { Text("Translate") }
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("Translation", style = MaterialTheme.typography.titleMedium)
                    Spacer(Modifier.height(6.dp))
                    Text(translation.ifEmpty { "Your translation will appear here." })
                    if (status.isNotEmpty()) { Spacer(Modifier.height(8.dp)); Text(status) }
                    Spacer(Modifier.height(16.dp))
                    OutlinedButton(onClick = { speech.speak(translation, target) }, enabled = translation.isNotBlank(), modifier = Modifier.fillMaxWidth()) { Text("🔊 Play translation") }
                    Spacer(Modifier.height(10.dp))
                    Button(onClick = { conversationMode = true; messages.value = emptyList(); status = "" }, modifier = Modifier.fillMaxWidth()) { Text("👥 Two-Person Conversation") }
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(onClick = { historyMode = true }, modifier = Modifier.fillMaxWidth()) { Text("🕘 Conversation History") }
                }
            }
        }
    }
}

@Composable
private fun ConversationScreen(
    source: AppLanguage,
    target: AppLanguage,
    messages: List<ConversationMessage>,
    listeningSpeaker: Int?,
    onBack: () -> Unit,
    onSwap: () -> Unit,
    onClear: () -> Unit,
    onStop: () -> Unit,
    onSpeak: (Int, AppLanguage, AppLanguage) -> Unit,
    status: String
) {
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
    }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedButton(onClick = onBack) { Text("Back") }
            Text("Conversation", style = MaterialTheme.typography.headlineSmall, modifier = Modifier.weight(1f))
            OutlinedButton(onClick = onSwap, enabled = listeningSpeaker == null) { Text("⇄") }
        }
        Spacer(Modifier.height(8.dp))
        Text("Person 1: ${source.displayName}  ↔  Person 2: ${target.displayName}")
        Spacer(Modifier.height(12.dp))
        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(messages) { message ->
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = if (message.speaker == 1) Arrangement.Start else Arrangement.End
                ) {
                    Card(Modifier.widthIn(max = 340.dp)) {
                        Column(Modifier.padding(12.dp)) {
                            Text("Person ${message.speaker} • ${message.source.displayName}", style = MaterialTheme.typography.labelMedium)
                            Spacer(Modifier.height(4.dp))
                            Text(message.original, style = MaterialTheme.typography.bodyLarge)
                            Spacer(Modifier.height(4.dp))
                            Text("→ ${message.translation}", style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
        }
        if (status.isNotEmpty()) { Text(status); Spacer(Modifier.height(6.dp)) }
        if (listeningSpeaker != null) {
            Button(onClick = onStop, modifier = Modifier.fillMaxWidth()) { Text("■ Stop Listening") }
            Spacer(Modifier.height(8.dp))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(
                onClick = { onSpeak(1, source, target) },
                enabled = listeningSpeaker == null,
                modifier = Modifier.weight(1f)
            ) { Text(if (listeningSpeaker == 1) "Listening…" else "🎙 Person 1") }
            Button(
                onClick = { onSpeak(2, target, source) },
                enabled = listeningSpeaker == null,
                modifier = Modifier.weight(1f)
            ) { Text(if (listeningSpeaker == 2) "Listening…" else "🎙 Person 2") }
        }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(onClick = onClear, enabled = messages.isNotEmpty() && listeningSpeaker == null, modifier = Modifier.fillMaxWidth()) { Text("Clear Current Conversation") }
    }
}

@Composable
private fun HistoryScreen(
    messages: List<ConversationMessage>,
    onBack: () -> Unit,
    onClear: () -> Unit
) {
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedButton(onClick = onBack) { Text("Back") }
            Text("History", style = MaterialTheme.typography.headlineSmall, modifier = Modifier.weight(1f))
            OutlinedButton(onClick = onClear, enabled = messages.isNotEmpty()) { Text("Clear") }
        }
        Spacer(Modifier.height(12.dp))
        if (messages.isEmpty()) {
            Text("No saved conversations yet.")
        } else {
            LazyColumn(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(messages) { message ->
                    Card(Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(12.dp)) {
                            Text("Person ${message.speaker} • ${message.source.displayName} → ${message.target.displayName}", style = MaterialTheme.typography.labelMedium)
                            Spacer(Modifier.height(4.dp))
                            Text(message.original, style = MaterialTheme.typography.bodyLarge)
                            Text("→ ${message.translation}", style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
        }
    }
}

private fun nextLanguage(current: AppLanguage): AppLanguage = when (current) {
    AppLanguage.ENGLISH -> AppLanguage.BULGARIAN
    AppLanguage.BULGARIAN -> AppLanguage.SPANISH
    AppLanguage.SPANISH -> AppLanguage.ENGLISH
}
