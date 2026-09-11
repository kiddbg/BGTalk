package com.kiddbg.bgtalk

data class ConversationMessage(
    val speaker: Int,
    val original: String,
    val translation: String,
    val source: AppLanguage,
    val target: AppLanguage
)
