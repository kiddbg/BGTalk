import SwiftUI

struct TranslationSettingsView: View {
    @AppStorage("translationEndpoint") private var translationEndpoint = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/translate", text: $translationEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Translation server URL")
                } footer: {
                    Text("Leave this blank to use BGTalk's development translator. A configured server must accept BGTalk's JSON translation request and return translatedText.")
                }

                Section("Request") {
                    Text("POST")
                    Text("JSON: text, sourceLanguage, targetLanguage")
                        .font(.footnote.monospaced())
                }
            }
            .navigationTitle("Translation Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TranslationSettingsView()
}
