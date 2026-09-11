import SwiftData
import SwiftUI

struct ConversationModeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var activeSpeaker = 0
    @State private var text = ""
    @State private var translation = ""
    @State private var isTranslating = false
    @State private var showPermissionAlert = false
    @State private var translationTask: Task<Void, Never>?
    @State private var translationGeneration = 0

    let firstLanguage: AppLanguage
    let secondLanguage: AppLanguage

    private let synthesizer = SpeechSynthesizer()

    private var sourceLanguage: AppLanguage {
        activeSpeaker == 0 ? firstLanguage : secondLanguage
    }

    private var targetLanguage: AppLanguage {
        activeSpeaker == 0 ? secondLanguage : firstLanguage
    }

    var body: some View {
        VStack(spacing: 14) {
            Label("Conversation mode", systemImage: "person.2.fill")
                .font(.headline)

            HStack(spacing: 10) {
                speakerButton(index: 0, language: firstLanguage, title: "Person 1")
                speakerButton(index: 1, language: secondLanguage, title: "Person 2")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Speaking: \(sourceLanguage.displayName)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(text.isEmpty ? "Tap the microphone and speak…" : text)
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                Text(isTranslating ? "Translating…" : (translation.isEmpty ? "Translation will appear here" : translation))
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                Task { await toggleListening() }
            } label: {
                Image(systemName: recognizer.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 82, height: 82)
                    .foregroundStyle(.white)
                    .background(recognizer.isListening ? Color.red : Color.accentColor, in: Circle())
            }
            .accessibilityLabel(recognizer.isListening ? "Stop listening" : "Start listening")

            if !translation.isEmpty {
                Button {
                    synthesizer.speak(translation, language: targetLanguage)
                } label: {
                    Label("Replay translation", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await recognizer.requestAuthorization()
            showPermissionAlert = recognizer.authorizationDenied
        }
        .onChange(of: recognizer.transcript) { _, newTranscript in
            guard recognizer.isListening else { return }
            scheduleLiveTranslation(for: newTranscript)
        }
        .onDisappear {
            translationTask?.cancel()
            recognizer.stopListening()
        }
        .alert("Microphone access needed", isPresented: $showPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("Allow microphone and speech recognition access in Settings to use conversation mode.")
        }
    }

    private func speakerButton(index: Int, language: AppLanguage, title: String) -> some View {
        Button {
            guard !recognizer.isListening else { return }
            activeSpeaker = index
            text = ""
            translation = ""
            translationTask?.cancel()
        } label: {
            VStack(spacing: 5) {
                Text(title).font(.caption.bold())
                Text(language.displayName).font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(activeSpeaker == index ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func toggleListening() async {
        if recognizer.isListening {
            translationTask?.cancel()
            translationGeneration += 1
            recognizer.stopListening()
            await translateFinal(recognizer.transcript)
            return
        }

        translationTask?.cancel()
        translationGeneration += 1
        text = ""
        translation = ""
        do {
            try recognizer.startListening(localeIdentifier: sourceLanguage.speechLocale)
        } catch {
            showPermissionAlert = true
        }
    }

    private func scheduleLiveTranslation(for value: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        translationTask?.cancel()
        translationGeneration += 1
        let generation = translationGeneration

        translationTask = Task {
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            await translatePreview(cleaned, generation: generation)
        }
    }

    private func translatePreview(_ value: String, generation: Int) async {
        do {
            let result = try await TranslationServiceFactory.makeService().translate(text: value, from: sourceLanguage, to: targetLanguage)
            guard !Task.isCancelled, generation == translationGeneration, recognizer.isListening else { return }
            text = value
            translation = result.translatedText
        } catch {
            guard !Task.isCancelled, generation == translationGeneration, recognizer.isListening else { return }
            translation = "Translation unavailable."
        }
    }

    private func translateFinal(_ value: String) async {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        text = cleaned
        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await TranslationServiceFactory.makeService().translate(text: cleaned, from: sourceLanguage, to: targetLanguage)
            translation = result.translatedText
            modelContext.insert(ConversationMessage(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage, sourceText: cleaned, translatedText: result.translatedText))
            try? modelContext.save()
            synthesizer.speak(result.translatedText, language: targetLanguage)
        } catch {
            translation = "Translation unavailable. Check Translation Server settings."
        }
    }
}

#Preview {
    ConversationModeView(firstLanguage: .english, secondLanguage: .bulgarian)
        .modelContainer(for: ConversationMessage.self, inMemory: true)
}
