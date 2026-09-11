import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case bulgarian = "bg"
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bulgarian: return "🇧🇬 Bulgarian"
        case .english: return "🇺🇸 English"
        case .spanish: return "🇪🇸 Spanish"
        }
    }

    var speechLocale: String {
        switch self {
        case .bulgarian: return "bg-BG"
        case .english: return "en-US"
        case .spanish: return "es-ES"
        }
    }
}
