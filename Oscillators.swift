import Foundation

enum GoaSoundBank: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case acid = "Acid"
    case celestial = "Celestial"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .classic: return "Original bass · Triangle lead · Harmonic pad"
        case .acid: return "Resonant bass · Psy FM lead · Fifth shimmer"
        case .celestial: return "Soft sub · Glass bell · Minor ninth cloud"
        }
    }
}


final class BassOscillator {
    var soundBank: GoaSoundBank = .classic
    private var frequency: Double = 55
    private var intensity: Double = 0.8
    private var phase: Double = 0
    private var envelopePhase: Double = 0
    private var isActive = false
    private let sampleRate: Double

    init(sampleRate: Double = 44100) {
        self.sampleRate = sampleRate
    }

    func setParameters(_ params: GoaTranceParameters) {
        intensity = params.bassIntensity
    }

    func triggerNote(frequency: Double) {
        self.frequency = frequency
        phase = 0
        envelopePhase = 0
        isActive = true
    }

    func generateSample() -> Float {
        guard isActive else { return 0 }

        phase = fmod(phase + frequency / sampleRate, 1.0)
        envelopePhase += 1.0 / sampleRate

        let attack = 0.015
        let decay = 0.18
        let releaseStart = 0.34
        let release = 0.22
        let envelope: Double

        if envelopePhase < attack {
            envelope = envelopePhase / attack
        } else if envelopePhase < attack + decay {
            envelope = 1.0 - ((envelopePhase - attack) / decay) * 0.32
        } else if envelopePhase < releaseStart {
            envelope = 0.68
        } else {
            let progress = (envelopePhase - releaseStart) / release
            envelope = max(0, 0.68 * (1.0 - progress))
            if progress >= 1 {
                isActive = false
            }
        }

        let saw = 2.0 * (phase - floor(phase + 0.5))
        let sine = sin(phase * 2.0 * .pi)
        let acidEdge = sin(phase * 2.0 * .pi * 3.0) * 0.18
        let sample: Double
        switch soundBank {
        case .classic: sample = saw * 0.55 + sine * 0.35 + acidEdge
        case .acid:
            // A decaying harmonic emphasis, with harmonics capped below Nyquist.
            let brightness = 1 + 7 * exp(-envelopePhase * 14)
            var tone = 0.0
            for h in 1...12 where Double(h) * frequency < sampleRate * 0.45 {
                let emphasis = exp(-pow((Double(h) - brightness) / 2, 2))
                tone += sin(phase * 2 * .pi * Double(h)) * (0.25 + emphasis) / Double(h)
            }
            sample = tanh(tone * 1.8) * 0.9
        case .celestial:
            sample = sine * 0.85 + sin(phase * 4 * .pi) * 0.12
        }

        return Float(sample * envelope * intensity * 0.34)
    }
}

final class MelodyOscillator {
    var soundBank: GoaSoundBank = .classic
    private var frequency: Double = 440
    private var complexity: Double = 0.5
    private var phase: Double = 0
    private var envelopePhase: Double = 0
    private var isActive = false
    private let sampleRate: Double

    init(sampleRate: Double = 44100) {
        self.sampleRate = sampleRate
    }

    func setParameters(_ params: GoaTranceParameters) {
        complexity = params.melodyComplexity
    }

    func triggerNote(frequency: Double) {
        self.frequency = frequency
        phase = 0
        envelopePhase = 0
        isActive = true
    }

    func generateSample() -> Float {
        guard isActive else { return 0 }

        phase = fmod(phase + frequency / sampleRate, 1.0)
        envelopePhase += 1.0 / sampleRate

        let attack = 0.01
        let decay = 0.11
        let releaseStart = 0.25 + complexity * 0.18
        let release = 0.16
        let envelope: Double

        if envelopePhase < attack {
            envelope = envelopePhase / attack
        } else if envelopePhase < attack + decay {
            envelope = 1.0 - ((envelopePhase - attack) / decay) * 0.38
        } else if envelopePhase < releaseStart {
            envelope = 0.62
        } else {
            let progress = (envelopePhase - releaseStart) / release
            envelope = max(0, 0.62 * (1.0 - progress))
            if progress >= 1 {
                isActive = false
            }
        }

        let triangle = abs(4.0 * (phase - floor(phase + 0.25))) - 2.0
        let harmonic = sin(phase * 4.0 * .pi) * 0.26
        let angle = phase * 2 * Double.pi
        let tone: Double
        switch soundBank {
        case .classic: tone = triangle * 0.56 + harmonic
        case .acid:
            let index = min(2.2, sampleRate / max(frequency, 1) / 16) * exp(-envelopePhase * 4)
            tone = sin(angle + sin(angle * 2) * index) * 0.85
        case .celestial:
            let partial = frequency * 2.756 < sampleRate * 0.45 ? sin(angle * 2.756) * exp(-envelopePhase * 8) * 0.35 : 0
            tone = sin(angle) * exp(-envelopePhase * 3) + partial
        }
        return Float(tone * envelope * 0.22)
    }
}

final class PadOscillator {
    var soundBank: GoaSoundBank = .classic
    private var intensity: Double = 0.45
    private var reverbAmount: Double = 0.55
    private var delayAmount: Double = 0.4
    private var phases = [Double](repeating: 0, count: 4)
    private var reverbBuffer: [Float]
    private var delayBuffer: [Float]
    private var reverbIndex = 0
    private var delayIndex = 0
    private let sampleRate: Double

    init(sampleRate: Double = 44100) {
        self.sampleRate = sampleRate
        reverbBuffer = [Float](repeating: 0, count: Int(sampleRate * 1.7))
        delayBuffer = [Float](repeating: 0, count: Int(sampleRate * 0.75))
    }

    func setParameters(_ params: GoaTranceParameters) {
        intensity = params.padIntensity
        reverbAmount = params.reverbAmount
        delayAmount = params.delayAmount
    }

    func generatePadSound(baseFrequency: Double) -> Float {
        let ratios: [Double]
        switch soundBank {
        case .classic: ratios = [1, 1.5, 2, 2.5]
        case .acid: ratios = [1, 1.4983, 2.003, 2.9966]
        case .celestial: ratios = [1, pow(2, 3.0 / 12), pow(2, 7.0 / 12), pow(2, 14.0 / 12)]
        }
        let frequencies = ratios.map { baseFrequency * $0 }

        var sample: Float = 0
        for index in frequencies.indices {
            phases[index] = fmod(phases[index] + frequencies[index] / sampleRate, 1.0)
            sample += Float(sin(phases[index] * 2.0 * .pi)) * Float(intensity) * 0.08
        }

        let wet = applyDelay(applyReverb(sample))
        return wet * 0.42
    }

    private func applyReverb(_ sample: Float) -> Float {
        guard !reverbBuffer.isEmpty else { return sample }
        reverbIndex = (reverbIndex + 1) % reverbBuffer.count
        let tail = reverbBuffer[reverbIndex]
        reverbBuffer[reverbIndex] = sample + tail * 0.62
        return sample + tail * Float(reverbAmount)
    }

    private func applyDelay(_ sample: Float) -> Float {
        guard !delayBuffer.isEmpty else { return sample }
        delayIndex = (delayIndex + 1) % delayBuffer.count
        let delayed = delayBuffer[delayIndex]
        delayBuffer[delayIndex] = sample + delayed * 0.48
        return sample + delayed * Float(delayAmount)
    }
}

final class DrumSynthesizer {
    private var noiseState: UInt32 = 0x13579BDF
    private func noiseSample() -> Float {
        noiseState = noiseState &* 1664525 &+ 1013904223
        return Float(Double(noiseState) / Double(UInt32.max) * 2 - 1)
    }
    private var kickDecay: Double = 0.42
    private var snareDecay: Double = 0.24
    private var hihatDecay: Double = 0.1
    private var kickPhase: Double = 0
    private var kickEnvelopePhase: Double = 0
    private var snareEnvelopePhase: Double = 0
    private var hihatEnvelopePhase: Double = 0
    private var kickActive = false
    private var snareActive = false
    private var hihatActive = false
    private let sampleRate: Double

    init(sampleRate: Double = 44100) {
        self.sampleRate = sampleRate
    }

    func setParameters(_ params: GoaTranceParameters) {
        kickDecay = 0.28 + params.bassIntensity * 0.32
        snareDecay = 0.22
        hihatDecay = 0.08 + params.frequencyCharacter.highAmount * 0.08
    }

    func triggerKick() {
        kickPhase = 0
        kickEnvelopePhase = 0
        kickActive = true
    }

    func triggerSnare() {
        snareEnvelopePhase = 0
        snareActive = true
    }

    func triggerHihat() {
        hihatEnvelopePhase = 0
        hihatActive = true
    }

    func generateKickSample() -> Float {
        guard kickActive else { return 0 }

        let pitchProgress = min(kickEnvelopePhase / 0.14, 1)
        let frequency = 150 - pitchProgress * 98
        kickPhase = fmod(kickPhase + frequency / sampleRate, 1.0)

        let envelope = max(0, 1.0 - kickEnvelopePhase / kickDecay)
        kickEnvelopePhase += 1.0 / sampleRate

        if kickEnvelopePhase > kickDecay {
            kickActive = false
        }

        return Float(sin(kickPhase * 2.0 * .pi) * envelope * 0.84)
    }

    func generateSnareSample() -> Float {
        guard snareActive else { return 0 }

        let envelope = max(0, 1.0 - snareEnvelopePhase / snareDecay)
        snareEnvelopePhase += 1.0 / sampleRate

        if snareEnvelopePhase > snareDecay {
            snareActive = false
        }

        return noiseSample() * Float(envelope) * 0.38
    }

    func generateHihatSample() -> Float {
        guard hihatActive else { return 0 }

        let envelope = max(0, 1.0 - hihatEnvelopePhase / hihatDecay)
        hihatEnvelopePhase += 1.0 / sampleRate

        if hihatEnvelopePhase > hihatDecay {
            hihatActive = false
        }

        let noise = noiseSample()
        return (noise - noise * 0.18) * Float(envelope) * 0.28
    }
}

final class MasterMixer {
    private let bass: BassOscillator
    private let melody: MelodyOscillator
    private let pad: PadOscillator
    private let drums: DrumSynthesizer
    private var masterGain: Float = 0.82

    init(sampleRate: Double = 44100) {
        bass = BassOscillator(sampleRate: sampleRate)
        melody = MelodyOscillator(sampleRate: sampleRate)
        pad = PadOscillator(sampleRate: sampleRate)
        drums = DrumSynthesizer(sampleRate: sampleRate)
    }

    func setParameters(_ params: GoaTranceParameters) {
        bass.setParameters(params)
        melody.setParameters(params)
        pad.setParameters(params)
        drums.setParameters(params)
        masterGain = Float(0.62 + params.overallIntensity * 0.22)
    }

    func setSoundBank(_ bank: GoaSoundBank) {
        bass.soundBank = bank
        melody.soundBank = bank
        pad.soundBank = bank
    }

    func generateMixedSample() -> Float {
        let mixed = bass.generateSample() * 0.44 +
            melody.generateSample() * 0.34 +
            pad.generatePadSound(baseFrequency: 110) * 0.22 +
            drums.generateKickSample() * 0.72 +
            drums.generateSnareSample() * 0.28 +
            drums.generateHihatSample() * 0.18

        return tanh(mixed * masterGain)
    }

    func triggerBass(frequency: Double) {
        bass.triggerNote(frequency: frequency)
    }

    func triggerMelody(frequency: Double) {
        melody.triggerNote(frequency: frequency)
    }

    func triggerKick() {
        drums.triggerKick()
    }

    func triggerSnare() {
        drums.triggerSnare()
    }

    func triggerHihat() {
        drums.triggerHihat()
    }
}
