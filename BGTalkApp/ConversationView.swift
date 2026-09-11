import SwiftUI
import SwiftData

struct ConversationView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var firstSpeakerRecognizer = SpeechRecognizer()
    @StateObject private var secondSpeakerRecognizer = SpeechRecognizer()
    @State private var firstLanguage: AppLanguage = .english
    @State private var secondLanguage: AppLanguage = .bulgarian
    @State private var activeSpeaker = 1
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var errorMessage: String?

    private let translationService: TranslationService = MockTranslationService()
    private let speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                languageControls
                speakerCard(number: 1, language: firstLanguage, recognizer: firstSpeakerRecognizer)
                speakerCard(number: 2, language: secondLanguage, recognizer: secondSpeakerRecognizer)
                translationCard
            }
            .padding()
        }
        .navigationTitle("Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Conversation error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onDisappear {
            firstSpeakerRecognizer.stopListening()
            secondSpeakerRecognizer.stopListening()
            speechSynthesizer.stop()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 34))
            Text("Talk naturally")
                .font(.title2.bold())
            Text("Choose a speaker, speak, and BGTalk will translate for the other person.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var languageControls: some View {
        HStack(spacing: 10) {
            languagePicker(title: "Person 1", selection: $firstLanguage)
            Button {
                let old = firstLanguage
                firstLanguage = secondLanguage
                secondLanguage = old
                translatedText = ""
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Swap conversation languages")
            languagePicker(title: "Person 2", selection: $secondLanguage)
        }
    }

    private func languagePicker(title: String, selection: Binding<AppLanguage>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func speakerCard(number: Int, language: AppLanguage, recognizer: SpeechRecognizer) -> some View {
        let isActive = activeSpeaker == number
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Person \(number)", systemImage: number == 1 ? "person.fill" : "person.fill")
                    .font(.headline)
                Spacer()
                Text(language.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Text(recognizer.transcript.isEmpty ? "Tap the microphone and speak…" : recognizer.transcript)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button {
                activeSpeaker = number
                Task { await toggleListening(number: number) }
            } label: {
                Label(recognizer.isListening ? "Stop & translate" : "Speak", systemImage: recognizer.isListening ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? .accentColor : .secondary)
            .disabled(isTranslating || (activeSpeaker != number && (firstSpeakerRecognizer.isListening || secondSpeakerRecognizer.isListening)))
        }
        .padding()
        .background(isActive ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 18))
    }

    private var translationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Translation").font(.headline)
            Text(isTranslating ? "Translating…" : (translatedText.isEmpty ? "The translated speech will appear here." : translatedText))
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

            if !translatedText.isEmpty {
                Button {
                    let target = activeSpeaker == 1 ? secondLanguage : firstLanguage
                    speechSynthesizer.speak(translatedText, language: target)
                } label: {
                    Label("Play translation", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func toggleListening(number: Int) async {
        let recognizer = number == 1 ? firstSpeakerRecognizer : secondSpeakerRecognizer
        if recognizer.isListening {
            recognizer.stopListening()
            await translate(recognizer.transcript, speaker: number)
            return
        }

        translatedText = ""
        do {
            try recognizer.startListening(localeIdentifier: (number == 1 ? firstLanguage : secondLanguage).speechLocale)
        } catch {
            errorMessage = "BGTalk could not start the microphone. Please check microphone and speech-recognition permissions."
        }
    }

    private func translate(_ text: String, speaker: Int) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        let source = speaker == 1 ? firstLanguage : secondLanguage
        let target = speaker == 1 ? secondLanguage : firstLanguage
        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await translationService.translate(text: cleaned, from: source, to: target)
            translatedText = result.translatedText
            modelContext.insert(ConversationMessage(sourceLanguage: source, targetLanguage: target, sourceText: cleaned, translatedText: result.translatedText))
            try? modelContext.save()
            speechSynthesizer.speak(result.translatedText, language: target)
        } catch {
            errorMessage = "Translation is currently unavailable."
        }
    }
}
