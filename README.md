# BGTalk iOS

BGTalk is an iPhone real-time conversation translation app focused on Bulgarian, English, and Spanish.

## Implemented foundation

- SwiftUI native iPhone interface
- Bulgarian, English, and Spanish language selection
- Native iOS speech recognition pipeline
- Language-specific speech locales
- Microphone and speech-recognition permission descriptions
- Translation service abstraction
- Translation result model
- Translated speech playback with AVSpeechSynthesizer
- Persistent local conversation history using SwiftData
- Language swapping
- Conversation-mode foundation
- XcodeGen project configuration

## Current development stage

The app now has the native capture → translation-service → speech-output architecture in place. The translation implementation is intentionally a mock service so the UI, persistence, speech recognition, and audio output can be developed independently of a translation provider.

## Remaining implementation stages

1. Connect the translation abstraction to a production translation provider.
2. Implement true streaming/partial-result translation.
3. Finish dedicated two-person conversation mode with speaker-specific controls.
4. Add settings and configurable speech behavior.
5. Add robust network, permission, and translation error states.
6. Add automated tests and production configuration.
7. Build and validate the app on a physical iPhone.

## Generating the Xcode project

The repository includes `project.yml` for XcodeGen. On a Mac with Xcode and XcodeGen installed, run:

```bash
xcodegen generate
open BGTalk.xcodeproj
```

The generated project uses the source files in `BGTalkApp/`.
