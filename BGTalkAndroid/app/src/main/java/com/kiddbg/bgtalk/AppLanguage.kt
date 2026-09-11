package com.kiddbg.bgtalk

enum class AppLanguage(
    val code: String,
    val displayName: String,
    val localeTag: String
) {
    BULGARIAN("bg", "Bulgarian", "bg-BG"),
    ENGLISH("en", "English", "en-US"),
    SPANISH("es", "Spanish", "es-ES")
}
