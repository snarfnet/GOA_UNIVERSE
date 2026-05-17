import Foundation

struct EmotionalCharacteristic {
    let emotion: Emotion
    let darkness: Double
    let intensity: Double
    let reverbAmount: Double
    let melodyComplexity: Double
    let tempo: Int
}

enum Emotion: String, CaseIterable {
    case sad = "SAD"
    case melancholic = "MELANCHOLIC"
    case euphoric = "EUPHORIC"
    case tense = "TENSE"
    case peaceful = "PEACEFUL"
    case energetic = "ENERGETIC"
}

final class EmotionalGoaTranceGenerator {
    static func calculateEmotionFromAnalysis(_ analysis: AudioAnalysisResult) -> Emotion {
        let lowRatio = analysis.frequencyBands.low
        let midRatio = analysis.frequencyBands.mid
        let highRatio = analysis.frequencyBands.high

        if lowRatio > 0.5 {
            return midRatio > 0.3 ? .melancholic : .sad
        }

        if analysis.estimatedBPM > 142 {
            return .energetic
        }

        if midRatio > 0.4 {
            return .euphoric
        }

        if highRatio > 0.4 {
            return .peaceful
        }

        return .melancholic
    }

    static func getEmotionalParameters(emotion: Emotion, baseBPM: Int) -> EmotionalCharacteristic {
        switch emotion {
        case .sad:
            return EmotionalCharacteristic(
                emotion: .sad,
                darkness: 0.9,
                intensity: 0.4,
                reverbAmount: 0.8,
                melodyComplexity: 0.6,
                tempo: max(100, baseBPM - 20)
            )
        case .melancholic:
            return EmotionalCharacteristic(
                emotion: .melancholic,
                darkness: 0.7,
                intensity: 0.5,
                reverbAmount: 0.7,
                melodyComplexity: 0.7,
                tempo: max(110, baseBPM - 10)
            )
        case .euphoric:
            return EmotionalCharacteristic(
                emotion: .euphoric,
                darkness: 0.3,
                intensity: 0.9,
                reverbAmount: 0.5,
                melodyComplexity: 0.8,
                tempo: min(155, baseBPM + 5)
            )
        case .tense:
            return EmotionalCharacteristic(
                emotion: .tense,
                darkness: 0.85,
                intensity: 0.8,
                reverbAmount: 0.6,
                melodyComplexity: 0.9,
                tempo: min(158, baseBPM + 10)
            )
        case .peaceful:
            return EmotionalCharacteristic(
                emotion: .peaceful,
                darkness: 0.2,
                intensity: 0.3,
                reverbAmount: 0.9,
                melodyComplexity: 0.4,
                tempo: max(90, baseBPM - 30)
            )
        case .energetic:
            return EmotionalCharacteristic(
                emotion: .energetic,
                darkness: 0.2,
                intensity: 0.95,
                reverbAmount: 0.3,
                melodyComplexity: 0.65,
                tempo: min(162, baseBPM + 20)
            )
        }
    }

    static func getEmotionLabel(_ emotion: Emotion) -> String {
        switch emotion {
        case .sad:
            return "SAD / DEEP"
        case .melancholic:
            return "MELANCHOLIC"
        case .euphoric:
            return "EUPHORIC"
        case .tense:
            return "TENSE / DARK"
        case .peaceful:
            return "PEACEFUL"
        case .energetic:
            return "ENERGETIC"
        }
    }

    static func applyEmotionalParameters(
        _ baseParams: GoaTranceParameters,
        emotion: EmotionalCharacteristic
    ) -> GoaTranceParameters {
        let scale = emotion.darkness > 0.7 ? [0, 3, 5, 7, 8, 11] : [0, 3, 5, 7, 10]

        return GoaTranceParameters(
            bpm: emotion.tempo,
            beatDuration: 60.0 / Double(emotion.tempo),
            key: baseParams.key,
            scaleType: baseParams.scaleType,
            rootNote: baseParams.rootNote,
            kickPattern: generateEmotionalKickPattern(emotion: emotion, basePattern: baseParams.kickPattern),
            hihatPattern: baseParams.hihatPattern,
            snarePattern: baseParams.snarePattern,
            clapPattern: baseParams.clapPattern,
            bassLineNotes: generateEmotionalBassLine(emotion: emotion, scale: scale, rootNote: baseParams.rootNote),
            bassOctave: baseParams.bassOctave,
            bassIntensity: min(max(emotion.darkness * 0.8 + 0.2, 0), 1),
            melodyNotes: generateEmotionalMelody(emotion: emotion, scale: scale, rootNote: baseParams.rootNote),
            melodyOctave: baseParams.melodyOctave,
            melodyComplexity: emotion.melodyComplexity,
            padIntensity: emotion.reverbAmount,
            reverbAmount: emotion.reverbAmount,
            delayAmount: min(max((emotion.darkness + emotion.melodyComplexity) * 0.3, 0), 1),
            overallIntensity: emotion.intensity,
            frequencyCharacter: baseParams.frequencyCharacter
        )
    }

    private static func generateEmotionalKickPattern(
        emotion: EmotionalCharacteristic,
        basePattern: [Bool]
    ) -> [Bool] {
        var pattern = basePattern

        switch emotion.emotion {
        case .sad, .melancholic, .peaceful:
            pattern = [Bool](repeating: false, count: 16)
            [0, 4, 8, 12].forEach { pattern[$0] = true }
        case .tense, .energetic:
            for index in stride(from: 0, to: 16, by: 2) {
                pattern[index] = true
            }
            if emotion.intensity > 0.8 {
                for index in stride(from: 1, to: 16, by: 2) where Bool.random() {
                    pattern[index] = true
                }
            }
        case .euphoric:
            pattern = [Bool](repeating: false, count: 16)
            [0, 4, 8, 12].forEach { pattern[$0] = true }
        }

        return pattern
    }

    private static func generateEmotionalBassLine(
        emotion: EmotionalCharacteristic,
        scale: [Int],
        rootNote: Int
    ) -> [Int] {
        let changeEvery = max(1, 16 / max(1, Int(emotion.melodyComplexity * 16)))
        var bassNotes: [Int] = []

        for index in 0..<16 {
            if index % changeEvery == 0 || bassNotes.isEmpty || Bool.random() {
                bassNotes.append(rootNote + scale.randomElement(or: 0) + 24)
            } else {
                bassNotes.append(bassNotes.last ?? rootNote + 24)
            }
        }

        return bassNotes
    }

    private static func generateEmotionalMelody(
        emotion: EmotionalCharacteristic,
        scale: [Int],
        rootNote: Int
    ) -> [Int] {
        let noteCount = Int(emotion.melodyComplexity * 24) + 8
        let descendingBias = emotion.darkness * 0.5

        return (0..<noteCount).map { _ in
            let octave = Double.random(in: 0...1) < descendingBias ? Int.random(in: 0...1) : Int.random(in: 1...3)
            return rootNote + scale.randomElement(or: 0) + octave * 12 + 48
        }
    }
}

private extension Array {
    func randomElement(or fallback: Element) -> Element {
        randomElement() ?? fallback
    }
}
