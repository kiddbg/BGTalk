import Foundation
import SwiftData

@Model
final class ConversationMessage {
    var id: UUID
    var createdAt: Date
    var sourceLanguage: String
    var targetLanguage: String
    var sourceText: String
    var translatedText: String

    init(
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage,
        sourceText: String,
        translatedText: String,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.sourceLanguage = sourceLanguage.rawValue
        self.targetLanguage = targetLanguage.rawValue
        self.sourceText = sourceText
        self.translatedText = translatedText
    }
}
