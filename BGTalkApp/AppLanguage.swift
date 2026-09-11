import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
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
}
