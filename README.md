# BGTalk iOS

BGTalk is an iPhone real-time conversation translation app focused on Bulgarian, English, and Spanish.

## Implemented foundation

- SwiftUI native iPhone interface
- Bulgarian, English, and Spanish language selection
- Native iOS speech recognition pipeline
- Language-specific speech locales
- Microphone and speech-recognition permission descriptions
- Translation service abstraction
- Generic remote translation backend client
- Translation result model
- Translated speech playback with AVSpeechSynthesizer
- Persistent local conversation history using SwiftData
- Language swapping
- Dedicated two-person conversation mode
- Automated iOS build and unit-test workflow
- XcodeGen project configuration

## Translation backend contract

BGTalk now includes a provider-independent `RemoteTranslationService`. It sends:

```json
{
  "text": "Hello",
  "sourceLanguage": "en",
  "targetLanguage": "bg"
}
```

and expects:

```json
{
  "translatedText": "Здравей"
}
```

This keeps provider credentials out of the iPhone app and allows the backend to use a production translation provider without changing the speech or UI layers.

## Current development stage

The native capture → translation-service → speech-output architecture is in place. The app currently uses a mock translator by default while the production backend is being prepared.

## Remaining implementation stages

1. Connect a production translation provider to the backend contract.
2. Wire the remote service into the app configuration.
3. Implement true streaming/partial-result translation.
4. Add settings and configurable speech behavior.
5. Add robust network, permission, and translation error states.
6. Expand automated tests and production configuration.
7. Build and validate the app on a physical iPhone.

## Generating the Xcode project

The repository includes `project.yml` for XcodeGen. On a Mac with Xcode and XcodeGen installed, run:

```bash
xcodegen generate
open BGTalk.xcodeproj
```

The generated project uses the source files in `BGTalkApp/`.
