# BGTalk iOS

BGTalk is an iPhone real-time conversation translation app focused on Bulgarian, English, and Spanish.

## Implemented foundation

- SwiftUI native iPhone interface
- Bulgarian, English, and Spanish language selection
- Native iOS speech recognition pipeline
- Microphone and speech-recognition permission descriptions
- Translation service abstraction
- Translation result model
- Translated speech playback with AVSpeechSynthesizer
- Basic conversation history in the UI
- XcodeGen project configuration

## Current development stage

The app now has the native capture → translation-service → speech-output architecture in place. The current translation implementation is intentionally a mock service so the UI and audio pipeline can be developed independently of a translation provider.

## Next implementation stages

1. Connect the translation abstraction to a production translation provider.
2. Improve streaming/partial-result translation so speech can be translated continuously.
3. Add dedicated two-person conversation mode with separate speakers.
4. Persist conversation history locally.
5. Add settings, error handling, and offline/connection states.
6. Add automated tests and production configuration.
7. Build and validate the app on a physical iPhone.

## Generating the Xcode project

The repository includes `project.yml` for XcodeGen. On a Mac with Xcode and XcodeGen installed, run:

```bash
xcodegen generate
open BGTalk.xcodeproj
```

The generated project uses the source files in `BGTalkApp/`.
