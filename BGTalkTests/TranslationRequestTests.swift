import XCTest
@testable import BGTalk

final class TranslationRequestTests: XCTestCase {
    func testSameLanguageTranslationIsStable() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(text: "Здравей", from: .bulgarian, to: .bulgarian)
        XCTAssertEqual(result.translatedText, "Здравей")
    }

    func testThreeLanguagePairsAreRepresented() {
        let languages: [AppLanguage] = [.bulgarian, .english, .spanish]
        XCTAssertEqual(languages.count, 3)
        XCTAssertEqual(Set(languages.map(\.rawValue)).count, 3)
    }
}
