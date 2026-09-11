import XCTest
@testable import BGTalk

final class LanguageCoverageTests: XCTestCase {
    func testAllSupportedLanguagesHaveSpeechLocales() {
        for language in AppLanguage.allCases {
            XCTAssertFalse(language.speechLocale.isEmpty)
        }
    }

    func testSupportedLanguageCodes() {
        XCTAssertEqual(Set(AppLanguage.allCases.map(\.rawValue)), Set(["bg", "en", "es"]))
    }
}
