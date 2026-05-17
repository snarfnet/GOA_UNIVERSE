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
