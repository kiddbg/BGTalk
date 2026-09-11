import Foundation

struct TranslationServiceFactory {
    private static let defaultEndpoint = "https://bgtalk-backend-production.up.railway.app/translate"

    static func makeService() -> any TranslationService {
        let configuredEndpoint = UserDefaults.standard.string(forKey: "translationEndpoint") ?? ""
        let endpointString = configuredEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultEndpoint
            : configuredEndpoint

        if let endpoint = URL(string: endpointString), endpoint.scheme != nil, endpoint.host != nil {
            return RemoteTranslationService(endpoint: endpoint)
        }
        return MockTranslationService()
    }
}
