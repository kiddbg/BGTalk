import SwiftData
import SwiftUI

@main
struct BGTalkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ConversationMessage.self)
    }
}
