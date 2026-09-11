import Foundation

struct TranslationServiceFactory {
    static func makeService() -> any TranslationService {
        let endpointString = UserDefaults.standard.string(forKey: "translationEndpoint") ?? ""
        if let endpoint = URL(string: endpointString), endpoint.scheme != nil, endpoint.host != nil {
            return RemoteTranslationService(endpoint: endpoint)
        }
        return MockTranslationService()
    }
}
