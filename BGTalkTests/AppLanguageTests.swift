import XCTest
@testable import BGTalk

final class AppLanguageTests: XCTestCase {
    func testAllSupportedLanguagesHaveSpeechLocales() {
        XCTAssertEqual(AppLanguage.allCases.count, 3)
        XCTAssertEqual(AppLanguage.bulgarian.speechLocale, "bg-BG")
        XCTAssertEqual(AppLanguage.english.speechLocale, "en-US")
        XCTAssertEqual(AppLanguage.spanish.speechLocale, "es-ES")
    }

    func testLanguageRoundTrip() {
        for language in AppLanguage.allCases {
            XCTAssertEqual(AppLanguage(rawValue: language.rawValue), language)
        }
    }
}
