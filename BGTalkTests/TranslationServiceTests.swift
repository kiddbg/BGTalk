import XCTest
@testable import BGTalk

final class TranslationServiceTests: XCTestCase {
    func testMockTranslationKeepsSameLanguageTextUnchanged() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(text: "Hello", from: .english, to: .english)
        XCTAssertEqual(result.translatedText, "Hello")
    }

    func testMockTranslationMarksTargetLanguage() async throws {
        let service = MockTranslationService()
        let result = try await service.translate(text: "Hello", from: .english, to: .bulgarian)
        XCTAssertEqual(result.translatedText, "[bg] Hello")
    }
}
