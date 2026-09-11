import SwiftUI

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var sourceLanguage: AppLanguage = .english
    @State private var targetLanguage: AppLanguage = .bulgarian
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var history: [ConversationLine] = []

    private let translationService: TranslationService = MockTranslationService()
    private let speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("BGTalk")
                        .font(.largeTitle.bold())
                    Text("Bulgarian • English • Spanish")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    LanguagePicker(title: "From", selection: $sourceLanguage)
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                    LanguagePicker(title: "To", selection: $targetLanguage)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("You")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(speechRecognizer.transcript.isEmpty ? "Speak into the microphone…" : speechRecognizer.transcript)
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                    Text("Translation")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(isTranslating ? "Translating…" : (translatedText.isEmpty ? "Your translation will appear here" : translatedText))
                        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }

                Button {
                    Task { await toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.white)
                        .background(speechRecognizer.isListening ? Color.red : Color.accentColor, in: Circle())
                }
                .accessibilityLabel(speechRecognizer.isListening ? "Stop listening" : "Start listening")

                Text(speechRecognizer.isListening ? "Listening…" : "Ready")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if !history.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(history) { line in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(line.source)
                                    Text(line.translation)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("BGTalk")
            .task {
                await speechRecognizer.requestAuthorization()
            }
            .onChange(of: speechRecognizer.transcript) { _, newValue in
                guard !newValue.isEmpty, !speechRecognizer.isListening else { return }
                Task { await translate(newValue) }
            }
        }
    }

    private func toggleListening() async {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
            await translate(speechRecognizer.transcript)
        } else {
            translatedText = ""
            let locale = sourceLanguage == .bulgarian ? "bg-BG" : sourceLanguage == .spanish ? "es-ES" : "en-US"
            try? speechRecognizer.startListening(localeIdentifier: locale)
        }
    }

    private func translate(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await translationService.translate(text: text, from: sourceLanguage, to: targetLanguage)
            translatedText = result.translatedText
            history.insert(ConversationLine(source: text, translation: result.translatedText), at: 0)
            speechSynthesizer.speak(result.translatedText, language: targetLanguage)
        } catch {
            translatedText = "Translation unavailable."
        }
    }
}

private struct ConversationLine: Identifiable {
    let id = UUID()
    let source: String
    let translation: String
}

private struct LanguagePicker: View {
    let title: String
    @Binding var selection: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(title, selection: $selection) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
