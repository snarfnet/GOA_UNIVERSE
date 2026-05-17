# GOA UNIVERSE

Goa trance generator for iOS, built with SwiftUI and AVFoundation.

The app analyzes an audio file, estimates tempo/key/frequency balance, then turns that signal into a real-time Goa trance pattern with kick, snare, hi-hat, bass, melody, pad, delay, and reverb.

## What It Does

- Select an audio file from the device.
- Analyze BPM, key, duration, sample rate, and low/mid/high frequency balance.
- Choose an emotion preset: sad, melancholic, euphoric, tense, peaceful, or energetic.
- Generate a 16-step Goa trance pattern from the analysis result.
- Play the generated synth engine in real time.
- Show a neon sequencer and frequency profile over a custom psychedelic background.
- Show a bottom banner ad with Google AdMob.

## Files

| File | Role |
| --- | --- |
| `App.swift` | SwiftUI app entry point |
| `ContentView.swift` | Main interface, file picker, controls, visual layout |
| `AudioAnalyzer.swift` | Audio loading, BPM/key estimation, frequency analysis |
| `GoaTranceParameters.swift` | Converts analysis data into musical parameters |
| `GoaTranceGenerator.swift` | AVAudioEngine setup and 16-step sequencing |
| `Oscillators.swift` | Bass, melody, pad, drum synth, and master mixer |
| `EmotionalGenerator.swift` | Emotion presets and emotional pattern shaping |
| `AdMobBannerView.swift` | Google AdMob banner integration |
| `Info.plist` | App metadata, AdMob app ID, SKAdNetwork identifiers |
| `Assets.xcassets` | Generated Goa trance background image |

## Project

Open:

```bash
C:\Users\Windows\GOA_UNIVERSE\GOA_UNIVERSE.xcodeproj
```

Then build and run in Xcode on an iOS simulator or device.

## Notes

- The original folder had Swift files only. This version adds `GOA_UNIVERSE.xcodeproj` so the app can be opened directly in Xcode.
- The visual background was generated with `imagegen` and saved into `Assets.xcassets` as `GoaPsyBackground`.
- Google Mobile Ads is added through Swift Package Manager.
- This environment does not include Swift or Xcode, so the project was not compiled here. The source has been cleaned so the previous mojibake-comment issue no longer comments out real code.

## Recommended Next Steps

- Build once in Xcode and set your Apple development team if signing asks for it.
- Test with a short MP3 or WAV first.
- If the simulator has audio glitches, try a physical iPhone. Real-time audio usually behaves better there.
