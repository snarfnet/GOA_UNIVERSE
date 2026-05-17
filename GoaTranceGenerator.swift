import AVFoundation
import AudioToolbox
import Foundation

final class GoaTranceGenerator: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentStep = 0
    @Published var parameters: GoaTranceParameters?

    private let sampleRate: Double = 44100
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var sequencerTimer: Timer?
    private var stepIndex = 0
    private var masterMixer: MasterMixer

    override init() {
        masterMixer = MasterMixer(sampleRate: sampleRate)
        super.init()
        setupAudio()
    }

    func loadAnalysisAndGenerate(from analysisResult: AudioAnalysisResult, emotion: Emotion? = nil) {
        var params = GoaTranceParameters.generateFromAnalysis(analysisResult)

        if let emotion {
            let emotionalParams = EmotionalGoaTranceGenerator.getEmotionalParameters(
                emotion: emotion,
                baseBPM: params.bpm
            )
            params = EmotionalGoaTranceGenerator.applyEmotionalParameters(params, emotion: emotionalParams)
        }

        parameters = params
        masterMixer.setParameters(params)
    }

    func play() {
        guard parameters != nil else { return }

        if engine?.isRunning != true {
            setupAudio()
        }

        isPlaying = true
        stepIndex = 0
        currentStep = 0
        processStep()
        startSequencer()
    }

    func stop() {
        isPlaying = false
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        currentStep = 0
    }

    private func setupAudio() {
        let engine = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                let sample = self?.isPlaying == true ? (self?.masterMixer.generateMixedSample() ?? 0) : 0

                for buffer in buffers {
                    guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    data[frame] = sample
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            self.engine = engine
            self.sourceNode = sourceNode
        } catch {
            print("Audio engine setup error: \(error)")
        }
    }

    private func startSequencer() {
        sequencerTimer?.invalidate()

        guard let params = parameters else { return }
        let secondsPerStep = params.beatDuration / 4.0

        sequencerTimer = Timer.scheduledTimer(withTimeInterval: secondsPerStep, repeats: true) { [weak self] _ in
            self?.processStep()
        }
    }

    private func processStep() {
        guard let params = parameters else { return }

        let step = stepIndex % 16
        currentStep = step

        if params.kickPattern[safe: step] == true {
            masterMixer.triggerKick()
        }

        if params.snarePattern[safe: step] == true || params.clapPattern[safe: step] == true {
            masterMixer.triggerSnare()
        }

        if params.hihatPattern[safe: step] == true {
            masterMixer.triggerHihat()
        }

        if let note = params.bassLineNotes[safe: step] {
            masterMixer.triggerBass(frequency: midiToFrequency(note))
        }

        if Double.random(in: 0...1) < params.melodyComplexity,
           let note = params.melodyNotes.randomElement() {
            masterMixer.triggerMelody(frequency: midiToFrequency(note))
        }

        stepIndex += 1
    }

    private func midiToFrequency(_ midiNote: Int) -> Double {
        440.0 * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    deinit {
        stop()
        engine?.stop()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
