import Foundation

struct TranslationResult: Codable, Sendable {
    let translatedText: String
}

protocol TranslationService: Sendable {
    func translate(text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult
}

enum TranslationServiceError: LocalizedError, Sendable {
    case invalidEndpoint
    case invalidResponse
    case serverError(Int)
    case emptyTranslation

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "The translation service URL is invalid."
        case .invalidResponse: return "The translation service returned an invalid response."
        case .serverError(let status): return "The translation service returned HTTP \(status)."
        case .emptyTranslation: return "The translation service returned no translated text."
        }
    }
}

/// Development-only translator used while the production backend is not configured.
struct MockTranslationService: TranslationService {
    func translate(text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult {
        if source == target {
            return TranslationResult(translatedText: text)
        }

        return TranslationResult(translatedText: "[\(target.rawValue)] \(text)")
    }
}

/// Generic BGTalk backend client. The server can be implemented with any translation provider.
/// Request JSON: { "text": "...", "sourceLanguage": "en", "targetLanguage": "bg" }
/// Response JSON: { "translatedText": "..." }
struct RemoteTranslationService: TranslationService {
    let endpoint: URL
    let session: URLSession

    init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func translate(text: String, from source: AppLanguage, to target: AppLanguage) async throws -> TranslationResult {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(
            TranslationRequest(text: text, sourceLanguage: source.rawValue, targetLanguage: target.rawValue)
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TranslationServiceError.serverError(httpResponse.statusCode)
        }

        do {
            let result = try JSONDecoder().decode(TranslationResult.self, from: data)
            guard !result.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw TranslationServiceError.emptyTranslation
            }
            return result
        } catch let error as TranslationServiceError {
            throw error
        } catch {
            throw TranslationServiceError.invalidResponse
        }
    }
}

private struct TranslationRequest: Codable, Sendable {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
}
