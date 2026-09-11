package com.kiddbg.bgtalk

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class ConversationHistoryStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("bgtalk_history", Context.MODE_PRIVATE)
    private val key = "messages"

    fun load(): List<ConversationMessage> {
        val raw = prefs.getString(key, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val item = array.getJSONObject(i)
                    val source = AppLanguage.entries.firstOrNull { it.code == item.getString("source") } ?: continue
                    val target = AppLanguage.entries.firstOrNull { it.code == item.getString("target") } ?: continue
                    add(ConversationMessage(
                        speaker = item.getInt("speaker"),
                        original = item.getString("original"),
                        translation = item.getString("translation"),
                        source = source,
                        target = target
                    ))
                }
            }
        }.getOrDefault(emptyList())
    }

    fun save(messages: List<ConversationMessage>) {
        val array = JSONArray()
        messages.forEach { message ->
            array.put(JSONObject().apply {
                put("speaker", message.speaker)
                put("original", message.original)
                put("translation", message.translation)
                put("source", message.source.code)
                put("target", message.target.code)
            })
        }
        prefs.edit().putString(key, array.toString()).apply()
    }

    fun clear() {
        prefs.edit().remove(key).apply()
    }
}
