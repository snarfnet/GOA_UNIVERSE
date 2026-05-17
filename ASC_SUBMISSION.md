# App Store Connect Submission Notes

## App Information

App name:
GOA UNIVERSE

Bundle ID:
com.snarfnet.goauniverse

Subtitle:
Psychedelic Trance Generator

Primary category:
Music

Secondary category:
Entertainment

Content rights:
The app generates audio locally. Do not include copyrighted song names in the App Store listing.

Age rating suggestion:
4+

## Japanese Store Listing

Promotional text:
音声ファイルの特徴を読み取り、Goa tranceのビート、ベース、メロディをその場で生成します。

Description:
GOA UNIVERSEは、音声ファイルからGoa tranceのパターンを作るシンセアプリです。

曲を読み込むと、テンポ、キー、低域・中域・高域のバランスを解析。結果に合わせて、キック、ハイハット、ベースライン、メロディ、パッドを組み立てます。

気分プリセットを選ぶと、暗さ、強さ、残響、メロディの密度が変わります。Melancholic、Euphoric、Tense、Peacefulなど、同じ素材から違う表情のトラックを鳴らせます。

できること:
- 音声ファイルのテンポとキーを推定
- 周波数バランスを解析
- Goa trance向けの16ステップパターンを生成
- ベース、メロディ、ドラム、パッドをリアルタイム再生
- 感情プリセットで雰囲気を調整
- ネオン曼荼羅のビジュアルで演奏状態を表示

音声処理は端末内で行います。読み込んだファイルを外部サーバーへ送信しません。

Keywords:
goa,trance,psytrance,techno,synth,sequencer,bpm,audio,music,ambient

Review notes:
This app analyzes a user-selected local audio file and generates a real-time Goa trance pattern on device. No account, login, server, analytics, ads, or tracking are used. To test, select any short MP3, WAV, or AIFF file, tap START ANALYSIS, tap GENERATE GOA TRANCE, then tap PLAY.


## English Store Listing

Promotional text:
Analyze an audio file and turn it into a real-time Goa trance pattern with drums, bass, melody, and pads.

Description:
GOA UNIVERSE is a Goa trance generator for iPhone and iPad.

Choose an audio file and the app estimates tempo, key, and frequency balance. It then builds a 16-step Goa trance pattern with kick, hi-hat, bassline, melody, pads, delay, and reverb.

Emotion presets change the feel of the generated track. Try Melancholic, Euphoric, Tense, Peaceful, and Energetic to shape the sound from the same source.

Features:
- Estimate BPM and key from a local audio file
- Analyze low, mid, and high frequency balance
- Generate Goa trance drum and bass patterns
- Play a real-time synth engine
- Shape the result with emotion presets
- Watch a neon sequencer over a psychedelic visual design

Audio processing happens on device. Selected files are not uploaded to a server.

Keywords:
goa,trance,psytrance,techno,synth,sequencer,bpm,audio,music,ambient


## App Privacy

Recommended App Privacy answer:
Data Collected

Reason:
The app uses Google AdMob banner ads. User-selected audio is still processed locally and is not uploaded by the app.

Suggested App Store Connect privacy entries to review:
- Third-Party Advertising
- Product Interaction
- Device ID or identifiers used by Google Mobile Ads SDK
- Diagnostics if reported by the SDK

Do not select "Data Not Collected" while AdMob is enabled.

Tracking:
This build does not request App Tracking Transparency permission. Ads should run without an IDFA prompt. If you later want personalized ads, add ATT and UMP consent flow before release.


## Required Before Upload

- Apple Developer Program membership.
- Mac with Xcode 26 or later.
- Bundle identifier `com.snarfnet.goauniverse` created in Apple Developer / App Store Connect.
- Development team set in Xcode.
- Google Mobile Ads Swift Package resolved in Xcode.
- Archive uploaded from Xcode Organizer.
- Privacy policy hosted at a public URL and updated for AdMob.
- iPhone screenshots.
- Support URL.
- Copyright holder name.
