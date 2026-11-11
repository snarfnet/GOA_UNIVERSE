import Foundation

struct GoaTranceParameters {
    let bpm: Int
    let beatDuration: Double
    let key: String
    let scaleType: ScaleType
    let rootNote: Int

    let kickPattern: [Bool]
    let hihatPattern: [Bool]
    let snarePattern: [Bool]
    let clapPattern: [Bool]

    let bassLineNotes: [Int]
    let bassOctave: Int
    let bassIntensity: Double

    let melodyNotes: [Int]
    let melodyOctave: Int
    let melodyComplexity: Double

    let padIntensity: Double
    let reverbAmount: Double
    let delayAmount: Double

    let overallIntensity: Double
    let frequencyCharacter: FrequencyCharacter

    static func generateFromAnalysis(_ analysis: AudioAnalysisResult) -> GoaTranceParameters {
        let bpm = min(max(analysis.estimatedBPM, 130), 150)
        let beatDuration = 60.0 / Double(bpm)
        let (key, scaleType, rootNote) = parseKey(analysis.estimatedKey)

        let freqChar = FrequencyCharacter(
            lowAmount: analysis.frequencyBands.low,
            midAmount: analysis.frequencyBands.mid,
            highAmount: analysis.frequencyBands.high
        )

        let bassIntensity = min(max(freqChar.lowAmount, 0.15), 1.0)
        let melodyComplexity = min(max(freqChar.midAmount + (Double(bpm - 130) / 20.0) * 0.3, 0.25), 1.0)
        let padIntensity = min(max(freqChar.highAmount, 0.18), 1.0)

        return GoaTranceParameters(
            bpm: bpm,
            beatDuration: beatDuration,
            key: key,
            scaleType: scaleType,
            rootNote: rootNote,
            kickPattern: generateKickPattern(freqChar: freqChar),
            hihatPattern: generateHihatPattern(bpm: bpm),
            snarePattern: generateSnarePattern(),
            clapPattern: generateClapPattern(),
            bassLineNotes: generateBassLine(rootNote: rootNote, intensity: bassIntensity),
            bassOctave: 1,
            bassIntensity: bassIntensity,
            melodyNotes: generateMelody(rootNote: rootNote, complexity: melodyComplexity),
            melodyOctave: 4,
            melodyComplexity: melodyComplexity,
            padIntensity: padIntensity,
            reverbAmount: min(max(0.25 + freqChar.highAmount * 0.65, 0), 1),
            delayAmount: min(max(0.35 + freqChar.midAmount * 0.35, 0), 1),
            overallIntensity: min(max(max(bassIntensity, freqChar.midAmount), 0.2), 1),
            frequencyCharacter: freqChar
        )
    }

    private static func parseKey(_ keyString: String) -> (String, ScaleType, Int) {
        let noteMap = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        let noteName = String(keyString.split(separator: " ").first ?? "A")
        let rootNote = noteMap[noteName] ?? 9
        let scaleType: ScaleType = keyString.localizedCaseInsensitiveContains("minor") ? .minor : .major
        return (keyString, scaleType, rootNote)
    }

    private static func generateKickPattern(freqChar: FrequencyCharacter) -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)

        for index in stride(from: 0, to: 16, by: 4) {
            pattern[index] = true
        }

        if freqChar.lowAmount > 0.38 {
            [2, 6, 10, 14].forEach { pattern[$0] = true }
        }

        if freqChar.lowAmount > 0.58 {
            [1, 9, 13].forEach { pattern[$0] = true }
        }

        return pattern
    }

    private static func generateHihatPattern(bpm: Int) -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)

        for index in stride(from: 0, to: 16, by: 2) {
            pattern[index] = true
        }

        if bpm > 140 {
            for index in stride(from: 1, to: 16, by: 2) {
                pattern[index] = Bool.random()
            }
        }

        return pattern
    }

    private static func generateSnarePattern() -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)
        pattern[4] = true
        pattern[12] = true
        if Bool.random() {
            pattern[8] = true
        }
        return pattern
    }

    private static func generateClapPattern() -> [Bool] {
        var pattern = [Bool](repeating: false, count: 16)
        [2, 6, 10, 14].forEach { pattern[$0] = true }
        return pattern
    }

    private static func generateBassLine(rootNote: Int, intensity: Double) -> [Int] {
        let scale = intensity > 0.55 ? [0, 3, 5, 7, 10] : [0, 3, 7, 10]

        return (0..<16).map { index in
            let step = scale[index % scale.count]
            return rootNote + step + 24
        }
    }

    private static func generateMelody(rootNote: Int, complexity: Double) -> [Int] {
        let scale = [0, 3, 5, 7, 10, 12]
        let stepCount = Int(16.0 * min(max(complexity, 0), 1)) + 4

        return (0..<stepCount).map { _ in
            let scaleIndex = Int.random(in: 0..<scale.count)
            let octave = Int.random(in: 0...2)
            return rootNote + scale[scaleIndex] + octave * 12 + 36
        }
    }
}

enum ScaleType: String, Codable {
    case major
    case minor
}

struct FrequencyCharacter: Codable {
    let lowAmount: Double
    let midAmount: Double
    let highAmount: Double
}

struct AudioAnalysisResult: Codable {
    let filename: String
    let duration: Double
    let sampleRate: Int
    let channels: Int
    let estimatedBPM: Int
    let estimatedKey: String
    let frequencyBands: FrequencyBands
    let analysisTimestamp: Date
}

struct FrequencyBands: Codable {
    let low: Double
    let mid: Double
    let high: Double
}

// Fixed arrangement rendered with the application's original oscillators and mixer.
// Musical events use the sample clock; rendering is reproducible from a fresh instance.
enum GoaSong {
    static let rate = 44_100
    static let bpm = 144
    static let bars = 108
    static let frames = rate * 180

    static func write(to url: URL) throws {
        let analysis = AudioAnalysisResult(filename: "Solstice Spiral", duration: 180,
            sampleRate: rate, channels: 1, estimatedBPM: bpm, estimatedKey: "A minor",
            frequencyBands: FrequencyBands(low: 0.6, mid: 0.7, high: 0.45), analysisTimestamp: Date(timeIntervalSince1970: 0))
        let mixer = MasterMixer(sampleRate: Double(rate))
        mixer.setParameters(GoaTranceParameters.generateFromAnalysis(analysis))
        let motif = [0, 7, 3, 12, 10, 7, 5, 3, 0, 12, 7, 15, 10, 5, 7, 3]
        var nextStep = 0.0
        var step = 0
        var pcm = Data(capacity: frames * 2)
        for frame in 0..<frames {
            if Double(frame) >= nextStep {
                let bar = step / 16
                let beat = step % 16
                let breakSection = (48..<64).contains(bar)
                let outro = bar >= 96
                let rhythm = bar >= 8 && !breakSection && bar < 104
                if rhythm && beat % 4 == 0 { mixer.triggerKick() }
                if rhythm && (beat % 4 == 2 || (bar >= 64 && beat % 2 == 1)) { mixer.triggerHihat() }
                if rhythm && bar >= 24 && (beat == 4 || beat == 12 || (bar % 8 == 7 && beat >= 14)) { mixer.triggerSnare() }
                if rhythm && beat % 4 != 0 {
                    let bassNote = 33 + ((bar % 8 == 7 && beat >= 12) ? 7 : 0)
                    mixer.triggerBass(frequency: frequency(bassNote))
                }
                if bar >= 16 && bar < 100 && (!outro || beat % 4 == 0) {
                    let sparse = breakSection || bar < 32
                    if !sparse || beat % 4 == 0 {
                        let offset = (bar / 4) % 4
                        let degree = motif[(beat + offset * 4) % 16]
                        let register = (bar >= 80 && bar % 4 >= 2) ? 12 : 0
                        mixer.triggerMelody(frequency: frequency(57 + degree + register))
                    }
                }
                step += 1
                nextStep += Double(rate) * 60 / Double(bpm) / 4
            }
            let edge = min(1, min(Double(frame) / Double(rate * 4), Double(frames - 1 - frame) / Double(rate * 8)))
            let sample = Double(mixer.generateMixedSample()) * edge
            guard sample.isFinite && abs(sample) <= 1 else { throw CocoaError(.fileWriteUnknown) }
            var value = Int16((sample * 32767).rounded()).littleEndian
            withUnsafeBytes(of: &value) { pcm.append(contentsOf: $0) }
        }
        var wav = Data()
        func text(_ s: String) { wav.append(contentsOf: s.utf8) }
        func u32(_ n: UInt32) { var v = n.littleEndian; withUnsafeBytes(of: &v) { wav.append(contentsOf: $0) } }
        func u16(_ n: UInt16) { var v = n.littleEndian; withUnsafeBytes(of: &v) { wav.append(contentsOf: $0) } }
        text("RIFF"); u32(UInt32(pcm.count + 36)); text("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        text("data"); u32(UInt32(pcm.count)); wav.append(pcm)
        try wav.write(to: url, options: .atomic)
    }

    private static func frequency(_ note: Int) -> Double {
        440 * pow(2, Double(note - 69) / 12)
    }
}
