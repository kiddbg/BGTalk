import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \.createdAt, order: .reverse) private var messages: [ConversationMessage]

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var sourceLanguage: AppLanguage = .english
    @State private var targetLanguage: AppLanguage = .bulgarian
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var conversationMode = false

    private let translationService: TranslationService = MockTranslationService()
    private let speechSynthesizer = SpeechSynthesizer()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    languageControls

                    if conversationMode {
                        conversationModeCard
                    }

                    messageComposer
                    historySection
                }
                .padding()
            }
            .navigationTitle("BGTalk")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Conversation mode", isOn: $conversationMode)
                        Button(role: .destructive) {
                            clearHistory()
                        } label: {
                            Label("Clear history", systemImage: "trash")
                        }
                        .disabled(messages.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await speechRecognizer.requestAuthorization()
            }
            .alert("Microphone access needed", isPresented: .constant(speechRecognizer.authorizationDenied)) {
                Button("OK") { }
            } message: {
                Text("Allow microphone and speech recognition access in Settings to use BGTalk voice translation.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("BGTalk")
                .font(.largeTitle.bold())
            Text("Bulgarian • English • Spanish")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var languageControls: some View {
        HStack(spacing: 10) {
            LanguagePicker(title: "From", selection: $sourceLanguage)

            Button {
                swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Swap languages")

            LanguagePicker(title: "To", selection: $targetLanguage)
        }
    }

    private var conversationModeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Two-person conversation", systemImage: "person.2.fill")
                .font(.headline)
            Text("Speak in \(sourceLanguage.displayName). BGTalk translates into \(targetLanguage.displayName) and can read the result aloud.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var messageComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your message")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(speechRecognizer.transcript.isEmpty ? "Speak into the microphone…" : speechRecognizer.transcript)
                .frame(maxWidth: .infinity, minHeight: 85, alignment: .topLeading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            Text("Translation")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(isTranslating ? "Translating…" : (translatedText.isEmpty ? "Your translation will appear here" : translatedText))
                .frame(maxWidth: .infinity, minHeight: 85, alignment: .topLeading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            HStack(spacing: 14) {
                Button {
                    Task { await toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .frame(width: 76, height: 76)
                        .foregroundStyle(.white)
                        .background(speechRecognizer.isListening ? Color.red : Color.accentColor, in: Circle())
                }
                .accessibilityLabel(speechRecognizer.isListening ? "Stop listening" : "Start listening")

                if !translatedText.isEmpty {
                    Button {
                        speechSynthesizer.speak(translatedText, language: targetLanguage)
                    } label: {
                        Label("Play", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Text(speechRecognizer.isListening ? "Listening…" : "Ready")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Conversation history")
                    .font(.headline)
                Spacer()
                Text("\(messages.count)")
                    .foregroundStyle(.secondary)
            }

            if messages.isEmpty {
                ContentUnavailableView("No conversations yet", systemImage: "bubble.left.and.bubble.right")
            } else {
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(languageName(for: message.sourceLanguage))
                                .font(.caption.bold())
                            Spacer()
                            Text(message.createdAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(message.sourceText)
                        Text(message.translatedText)
                            .foregroundStyle(.secondary)

                        Button {
                            let target = AppLanguage(rawValue: message.targetLanguage) ?? .bulgarian
                            speechSynthesizer.speak(message.translatedText, language: target)
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func toggleListening() async {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
            await translate(speechRecognizer.transcript)
        } else {
            translatedText = ""
            try? speechRecognizer.startListening(localeIdentifier: sourceLanguage.speechLocale)
        }
    }

    private func translate(_ text: String) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await translationService.translate(
                text: cleaned,
                from: sourceLanguage,
                to: targetLanguage
            )
            translatedText = result.translatedText

            modelContext.insert(
                ConversationMessage(
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    sourceText: cleaned,
                    translatedText: result.translatedText
                )
            )
            try? modelContext.save()
            speechSynthesizer.speak(result.translatedText, language: targetLanguage)
        } catch {
            translatedText = "Translation unavailable."
        }
    }

    private func swapLanguages() {
        let oldSource = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = oldSource
        translatedText = ""
    }

    private func clearHistory() {
        for message in messages {
            modelContext.delete(message)
        }
        try? modelContext.save()
    }

    private func languageName(for code: String) -> String {
        AppLanguage(rawValue: code)?.displayName ?? code.uppercased()
    }
}

private struct LanguagePicker: View {
    let title: String
    @Binding var selection: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ConversationMessage.self, inMemory: true)
}
