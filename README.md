# BGTalk iOS

BGTalk is an iPhone real-time conversation translation app focused on Bulgarian, English, and Spanish.

## Implemented

- SwiftUI native iPhone interface
- Bulgarian, English, and Spanish language selection
- Native iOS speech recognition pipeline
- Language-specific speech locales
- Microphone and speech-recognition permission descriptions
- Remote translation backend client
- Production backend hosted on Railway
- Google Cloud Translation integration with API-key fallback support
- Real-time partial-result translation with debounce and stale-request protection
- Final translation saved to SwiftData conversation history
- Translated speech playback with AVSpeechSynthesizer
- Two-person conversation mode
- Language-specific speech synthesis
- XcodeGen project configuration
- Automated unit-test coverage for supported languages and translation behavior

## Translation backend contract

BGTalk sends:

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

Provider credentials remain on the backend and are never embedded in the iPhone app.

## Production backend

The Railway service uses `/BGTalkBackend` as its root directory, listens on port 8080, and exposes `/health` and `/translate` endpoints.

The iOS app defaults to the production translation endpoint:

`https://bgtalk-backend-production.up.railway.app/translate`

A custom endpoint can still be configured through the app's translation-service setting.

## Remaining steps

1. Configure the Google Translation credential directly in Railway.
2. Generate the Xcode project on a Mac with XcodeGen.
3. Build and run the unit tests in Xcode.
4. Install on a physical iPhone and validate microphone, speech recognition, Bulgarian/English/Spanish translation, and speech playback.
5. Tune latency and translation behavior after real-device testing.

## Generating the Xcode project

On a Mac with Xcode and XcodeGen installed:

```bash
xcodegen generate
open BGTalk.xcodeproj
```

The generated project uses the source files in `BGTalkApp/`.
