package com.kiddbg.bgtalk

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { BGTalkScreen() }
    }
}

@Composable
private fun BGTalkScreen() {
    var source by rememberSaveable { mutableStateOf("English") }
    var target by rememberSaveable { mutableStateOf("Bulgarian") }
    var text by rememberSaveable { mutableStateOf("") }
    var translation by rememberSaveable { mutableStateOf("") }

    MaterialTheme {
        Column(
            modifier = Modifier.fillMaxSize().padding(20.dp),
            verticalArrangement = Arrangement.Top
        ) {
            Text("BGTalk", style = MaterialTheme.typography.headlineLarge)
            Text("Bulgarian • English • Spanish", style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.height(20.dp))

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = { source = nextLanguage(source) }, modifier = Modifier.weight(1f)) {
                    Text(source)
                }
                Button(onClick = {
                    val old = source
                    source = target
                    target = old
                }) { Text("⇄") }
                OutlinedButton(onClick = { target = nextLanguage(target) }, modifier = Modifier.weight(1f)) {
                    Text(target)
                }
            }

            Spacer(Modifier.height(16.dp))
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Speak or type") },
                minLines = 4
            )
            Spacer(Modifier.height(12.dp))
            Button(onClick = { translation = "Translation will connect to the BGTalk backend." }, modifier = Modifier.fillMaxWidth()) {
                Text("Translate")
            }
            Spacer(Modifier.height(16.dp))
            Text("Translation", style = MaterialTheme.typography.titleMedium)
            Spacer(Modifier.height(6.dp))
            Text(translation.ifEmpty { "Your translation will appear here." })
            Spacer(Modifier.height(24.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = { }, modifier = Modifier.weight(1f)) { Text("🎙 Speak") }
                OutlinedButton(onClick = { }, modifier = Modifier.weight(1f)) { Text("🔊 Play") }
            }
        }
    }
}

private fun nextLanguage(current: String): String = when (current) {
    "English" -> "Bulgarian"
    "Bulgarian" -> "Spanish"
    else -> "English"
}
