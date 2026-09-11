import AVFoundation
import Foundation

@MainActor
final class SpeechSynthesizer {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, language: AppLanguage) {
        guard !text.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode(for: language))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func voiceLanguageCode(for language: AppLanguage) -> String {
        switch language {
        case .bulgarian: return "bg-BG"
        case .english: return "en-US"
        case .spanish: return "es-ES"
        }
    }
}
