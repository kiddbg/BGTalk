# BGTalk

BGTalk is a real-time conversation translation app focused on Bulgarian, English, and Spanish.

## Android version

The Android version is being developed as the current priority. It includes:

- Native Android/Jetpack Compose interface
- Bulgarian, English, and Spanish language selection
- Android speech recognition with partial results
- Real-time partial-result translation with debounce
- Two-person conversation mode with turn-taking controls
- Language-specific translated speech playback
- Persistent conversation history
- Remote translation backend using the production Railway `/translate` endpoint
- Automatic GitHub Actions debug-APK builds

### Android build

The Android project is located in `BGTalkAndroid/` and targets Android 15 (SDK 35), with Android 8.0+ (API 26) minimum support. Every push to `main` runs the Android build workflow and uploads the resulting debug APK as a GitHub Actions artifact.

The Android app currently uses:

`https://bgtalk-backend-production.up.railway.app/translate`

## iOS version

The iOS version includes:

- SwiftUI native iPhone interface
- Bulgarian, English, and Spanish language selection
- Native iOS speech recognition pipeline
- Language-specific speech locales
- Microphone and speech-recognition permission descriptions
- Remote translation backend client
- Production backend hosted on Railway
- DeepL Translation integration with backend-only API credentials
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

Provider credentials remain on the backend and are never embedded in either mobile app.

## Production backend

The Railway service uses `/BGTalkBackend` as its root directory, listens on port 8080, and exposes `/health` and `/translate` endpoints.

The production backend uses the DeepL API. Railway expects the secret environment variable `DEEPL_API_KEY`; the key is never committed to GitHub or included in the mobile applications.

## Remaining Android validation

1. Confirm the GitHub Actions Android debug build completes successfully.
2. Download the generated debug APK artifact and install it on a physical Android phone.
3. Validate microphone permissions and speech recognition.
4. Validate Bulgarian/English/Spanish translation against the production backend.
5. Validate translated speech through the phone speaker and connected headphones.
6. Tune latency, audio routing, and conversation turn-taking after real-device testing.

## Remaining iOS validation

1. Verify the Railway deployment and DeepL translation endpoint.
2. Generate the Xcode project on a Mac with XcodeGen.
3. Build and run the unit tests in Xcode.
4. Install on a physical iPhone and validate microphone, speech recognition, Bulgarian/English/Spanish translation, and speech playback.
5. Tune latency and translation behavior after real-device testing.
