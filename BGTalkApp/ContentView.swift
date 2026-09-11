import SwiftUI

struct ContentView: View {
    @State private var sourceLanguage: AppLanguage = .english
    @State private var targetLanguage: AppLanguage = .bulgarian
    @State private var isListening = false
    @State private var transcript = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("BGTalk")
                        .font(.largeTitle.bold())
                    Text("Real-time conversation translation")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    LanguagePicker(title: "From", selection: $sourceLanguage)
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                    LanguagePicker(title: "To", selection: $targetLanguage)
                }

                Text(transcript.isEmpty ? "Tap the microphone to start speaking" : transcript)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                Button {
                    isListening.toggle()
                } label: {
                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.white)
                        .background(isListening ? Color.red : Color.accentColor, in: Circle())
                }
                .accessibilityLabel(isListening ? "Stop listening" : "Start listening")

                Text(isListening ? "Listening…" : "Ready")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("BGTalk")
        }
    }
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
