import Foundation

struct TranslationResult: Codable, Sendable {
    let translatedText: String
}

protocol TranslationService: Sendable {
    func translate(text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult
}

struct MockTranslationService: TranslationService {
    func translate(text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult {
        if source == target {
            return TranslationResult(translatedText: text)
        }

        return TranslationResult(
            translatedText: "[\(target.rawValue)] \(text)"
        )
    }
}
