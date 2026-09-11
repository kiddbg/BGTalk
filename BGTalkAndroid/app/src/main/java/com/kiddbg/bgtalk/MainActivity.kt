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
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
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
    val scope = rememberCoroutineScope()
    val service = remember { TranslationService() }
    val context = LocalContext.current
    val speech = remember(context) { SpeechManager(context) }

    DisposableEffect(Unit) { onDispose { speech.release() } }

    MaterialTheme {
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
                Button(onClick = { speech.startListening(source, { result -> text = result }, { error -> status = error }) }, modifier = Modifier.weight(1f)) { Text("🎙 Speak") }
                Button(onClick = { scope.launch { status = "Translating…"; try { translation = service.translate(text, source, target); status = "" } catch (error: Exception) { status = error.message ?: "Translation failed" } } }, enabled = text.isNotBlank(), modifier = Modifier.weight(1f)) { Text("Translate") }
            }
            Spacer(Modifier.height(16.dp))
            Text("Translation", style = MaterialTheme.typography.titleMedium)
            Spacer(Modifier.height(6.dp))
            Text(translation.ifEmpty { "Your translation will appear here." })
            if (status.isNotEmpty()) { Spacer(Modifier.height(8.dp)); Text(status) }
            Spacer(Modifier.height(16.dp))
            OutlinedButton(onClick = { speech.speak(translation, target) }, enabled = translation.isNotBlank(), modifier = Modifier.fillMaxWidth()) { Text("🔊 Play translation") }
        }
    }
}

private fun nextLanguage(current: AppLanguage): AppLanguage = when (current) {
    AppLanguage.ENGLISH -> AppLanguage.BULGARIAN
    AppLanguage.BULGARIAN -> AppLanguage.SPANISH
    AppLanguage.SPANISH -> AppLanguage.ENGLISH
}
