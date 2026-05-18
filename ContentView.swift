import SwiftUI
import UniformTypeIdentifiers
import AppTrackingTransparency
import GoogleMobileAds

struct ContentView: View {
    @StateObject private var analyzer = AudioAnalyzer()
    @StateObject private var generator = GoaTranceGenerator()
    @State private var selectedAudioURL: URL?
    @State private var showFilePicker = false
    @State private var selectedEmotion: Emotion = .melancholic
    @State private var adsReady = false

    private let cyan = Color(red: 0.25, green: 0.95, blue: 0.88)
    private let gold = Color(red: 1.0, green: 0.78, blue: 0.22)
    private let magenta = Color(red: 1.0, green: 0.22, blue: 0.72)

    var body: some View {
        ZStack {
            GoaBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    filePanel
                    analysisPanel

                    if let results = analyzer.analysisResults {
                        detectedPanel(results)
                    }

                    if generator.parameters != nil {
                        playbackPanel
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 34)
                .padding(.bottom, 92)
            }

            VStack {
                Spacer()
                if adsReady {
                    AdMobBannerView()
                        .frame(width: 320, height: 50)
                        .background(Color.black.opacity(0.48))
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .task {
            await prepareAds()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio],
            onCompletion: handleFileSelection
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("GOA UNIVERSE")
                .font(.system(size: 36, weight: .black))
                .tracking(5)
                .foregroundStyle(
                    LinearGradient(colors: [cyan, gold, magenta], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: cyan.opacity(0.8), radius: 18)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            HStack(spacing: 8) {
                NeonPill(text: "\(generator.parameters?.bpm ?? analyzer.analysisResults?.estimatedBPM ?? 144) BPM", color: gold)
                NeonPill(text: selectedEmotion.rawValue, color: magenta)
                NeonPill(text: generator.isPlaying ? "LIVE" : "ARMED", color: cyan)
            }
        }
        .padding(.bottom, 6)
    }

    private var filePanel: some View {
        GoaPanel(title: "SOURCE SIGNAL") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(cyan.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: "waveform")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(cyan)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedAudioURL?.lastPathComponent ?? "No audio selected")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("MP3 / WAV / AIFF")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.52))
                    }

                    Spacer()
                }

                GoaButton(title: "SELECT AUDIO FILE", color: cyan, icon: "folder.fill") {
                    showFilePicker = true
                }
            }
        }
    }

    private var analysisPanel: some View {
        GoaPanel(title: "ANALYSIS ENGINE") {
            if analyzer.isAnalyzing {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(cyan)
                    Text("ANALYZING SIGNAL...")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(cyan)
                    Spacer()
                }
                .frame(height: 44)
            } else {
                GoaButton(
                    title: "START ANALYSIS",
                    color: selectedAudioURL == nil ? .white.opacity(0.35) : gold,
                    icon: "scope"
                ) {
                    if let selectedAudioURL {
                        analyzer.analyzeAudioFile(at: selectedAudioURL)
                    }
                }
                .disabled(selectedAudioURL == nil)
            }
        }
    }

    private func detectedPanel(_ results: AudioAnalysisResult) -> some View {
        GoaPanel(title: "DETECTED PARAMETERS") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ParameterTile(label: "BPM", value: "\(results.estimatedBPM)", color: gold)
                    ParameterTile(label: "KEY", value: results.estimatedKey, color: cyan)
                    ParameterTile(label: "TIME", value: String(format: "%.0fs", results.duration), color: magenta)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("FREQUENCY PROFILE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.58))

                    HStack(spacing: 10) {
                        FrequencyBar(label: "LOW", value: results.frequencyBands.low, color: magenta)
                        FrequencyBar(label: "MID", value: results.frequencyBands.mid, color: cyan)
                        FrequencyBar(label: "HIGH", value: results.frequencyBands.high, color: gold)
                    }
                }

                VStack(spacing: 10) {
                    HStack {
                        Text("EMOTION PRESET")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.58))
                        Spacer()
                        Text(EmotionalGoaTranceGenerator.getEmotionLabel(selectedEmotion))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(gold)
                            .lineLimit(1)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Emotion.allCases, id: \.self) { emotion in
                                Button {
                                    selectedEmotion = emotion
                                } label: {
                                    Text(emotion.rawValue)
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                        .foregroundColor(selectedEmotion == emotion ? .black : cyan)
                                        .padding(.horizontal, 12)
                                        .frame(height: 30)
                                        .background(selectedEmotion == emotion ? gold : Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(selectedEmotion == emotion ? gold : cyan.opacity(0.25), lineWidth: 1)
                                        )
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }

                GoaButton(title: "GENERATE GOA TRANCE", color: magenta, icon: "sparkles") {
                    generator.loadAnalysisAndGenerate(from: results, emotion: selectedEmotion)
                }
            }
        }
    }

    private var playbackPanel: some View {
        GoaPanel(title: "LIVE SEQUENCER") {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(0..<16, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == generator.currentStep && generator.isPlaying ? gold : cyan.opacity(index % 4 == 0 ? 0.55 : 0.22))
                            .frame(height: index % 4 == 0 ? 34 : 24)
                            .shadow(color: index == generator.currentStep ? gold.opacity(0.9) : .clear, radius: 8)
                    }
                }
                .frame(height: 36)

                HStack(spacing: 10) {
                    GoaButton(
                        title: generator.isPlaying ? "STOP" : "PLAY",
                        color: generator.isPlaying ? Color(red: 1, green: 0.18, blue: 0.22) : cyan,
                        icon: generator.isPlaying ? "stop.fill" : "play.fill"
                    ) {
                        generator.isPlaying ? generator.stop() : generator.play()
                    }

                    Text("STEP \(generator.currentStep + 1)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(cyan)
                        .frame(width: 82, height: 44)
                        .background(Color.black.opacity(0.38))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(cyan.opacity(0.34), lineWidth: 1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<URL, Error>) {
        if case .success(let url) = result {
            selectedAudioURL = url
        }
    }

    @MainActor
    private func prepareAds() async {
        guard !adsReady else { return }

        if #available(iOS 14, *) {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                ATTrackingManager.requestTrackingAuthorization { _ in
                    continuation.resume()
                }
            }
        }

        MobileAds.shared.start()
        adsReady = true
    }
}

private struct GoaBackground: View {
    var body: some View {
        ZStack {
            Image("GoaPsyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.56),
                    Color.black.opacity(0.84)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.72)],
                center: .center,
                startRadius: 80,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }
}

private struct GoaPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.66))
                .tracking(1.4)

            content
        }
        .padding(14)
        .background(.ultraThinMaterial.opacity(0.76))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.32), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 12)
    }
}

private struct GoaButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color)
            .overlay(LinearGradient(colors: [.white.opacity(0.32), .clear], startPoint: .top, endPoint: .bottom))
            .cornerRadius(8)
            .shadow(color: color.opacity(0.48), radius: 14)
        }
    }
}

private struct NeonPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(Color.black.opacity(0.42))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.55), lineWidth: 1))
            .cornerRadius(13)
    }
}

private struct ParameterTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.48))

            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.black.opacity(0.36))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.32), lineWidth: 1))
        .cornerRadius(8)
    }
}

private struct FrequencyBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.09))

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: max(5, CGFloat(min(max(value, 0), 1)) * 72))
                    .shadow(color: color.opacity(0.7), radius: 7)
            }
            .frame(height: 72)

            Text(label)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(color)

            Text(String(format: "%.0f%%", min(max(value, 0), 1) * 100))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.56))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
