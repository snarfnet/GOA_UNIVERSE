import Foundation
import AVFoundation

final class AudioAnalyzer: NSObject, ObservableObject {
    @Published var analysisResults: AudioAnalysisResult?
    @Published var isAnalyzing = false

    func analyzeAudioFile(at url: URL) {
        isAnalyzing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let audioFile = try AVAudioFile(forReading: url)
                guard let audioBuffer = AVAudioPCMBuffer(
                    pcmFormat: audioFile.processingFormat,
                    frameCapacity: AVAudioFrameCount(audioFile.length)
                ) else {
                    DispatchQueue.main.async { self?.isAnalyzing = false }
                    return
                }

                try audioFile.read(into: audioBuffer)

                let sampleRate = Float(audioFile.processingFormat.sampleRate)
                let duration = Double(audioFile.length) / Double(sampleRate)
                let channelCount = Int(audioFile.processingFormat.channelCount)
                let samples = Self.monoSamples(from: audioBuffer)

                let result = AudioAnalysisResult(
                    filename: url.lastPathComponent,
                    duration: duration,
                    sampleRate: Int(sampleRate),
                    channels: channelCount,
                    estimatedBPM: Self.estimateBPM(samples: samples, sampleRate: sampleRate),
                    estimatedKey: Self.estimateKey(samples: samples, sampleRate: sampleRate),
                    frequencyBands: Self.analyzeFrequencyBands(samples: samples, sampleRate: sampleRate),
                    analysisTimestamp: Date()
                )

                DispatchQueue.main.async {
                    self?.analysisResults = result
                    self?.isAnalyzing = false
                }
            } catch {
                print("Audio analysis error: \(error)")
                DispatchQueue.main.async { self?.isAnalyzing = false }
            }
        }
    }

    private static func monoSamples(from audioBuffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = audioBuffer.floatChannelData else { return [] }

        let frameLength = Int(audioBuffer.frameLength)
        let channelCount = Int(audioBuffer.format.channelCount)
        var samples = [Float](repeating: 0, count: frameLength)

        for channel in 0..<channelCount {
            let buffer = UnsafeBufferPointer(start: channelData[channel], count: frameLength)
            for index in 0..<frameLength {
                samples[index] += buffer[index] / Float(channelCount)
            }
        }

        return samples
    }

    private static func analyzeFrequencyBands(samples: [Float], sampleRate: Float) -> FrequencyBands {
        guard !samples.isEmpty else {
            return FrequencyBands(low: 0, mid: 0, high: 0)
        }

        let windowSize = min(2048, samples.count)
        let bins = frequencyMagnitudes(samples: samples, sampleRate: sampleRate, windowSize: windowSize)
        let low = bins.filter { $0.frequency < 150 }.map(\.magnitude).reduce(0, +)
        let mid = bins.filter { $0.frequency >= 150 && $0.frequency < 4000 }.map(\.magnitude).reduce(0, +)
        let high = bins.filter { $0.frequency >= 4000 }.map(\.magnitude).reduce(0, +)
        let total = max(low + mid + high, 0.0001)

        return FrequencyBands(
            low: Double(low / total),
            mid: Double(mid / total),
            high: Double(high / total)
        )
    }

    private static func estimateBPM(samples: [Float], sampleRate: Float) -> Int {
        guard samples.count > Int(sampleRate) else { return 140 }

        let hopSize = max(1, Int(sampleRate * 0.02))
        var energies: [Float] = []

        for index in stride(from: 0, to: samples.count - hopSize, by: hopSize) {
            let frame = samples[index..<index + hopSize]
            let energy = frame.reduce(Float(0)) { $0 + abs($1) }
            energies.append(energy)
        }

        guard energies.count > 8 else { return 140 }

        let average = energies.reduce(0, +) / Float(energies.count)
        let variance = energies.reduce(Float(0)) { $0 + pow($1 - average, 2) } / Float(energies.count)
        let movement = min(max(Double(sqrt(variance) / max(average, 0.0001)), 0), 1)
        return min(max(Int(132 + movement * 18), 130), 150)
    }

    private static func estimateKey(samples: [Float], sampleRate: Float) -> String {
        guard !samples.isEmpty else { return "A minor" }

        let windowSize = min(4096, samples.count)
        let bins = frequencyMagnitudes(samples: samples, sampleRate: sampleRate, windowSize: windowSize)
        let peak = bins
            .filter { $0.frequency >= 55 && $0.frequency <= 220 }
            .max { $0.magnitude < $1.magnitude }

        guard let peakFrequency = peak?.frequency else { return "A minor" }

        let keys: [(name: String, frequency: Float)] = [
            ("A minor", 110.0),
            ("E minor", 82.41),
            ("D minor", 73.42),
            ("G minor", 98.0)
        ]

        return keys.min {
            abs(peakFrequency - $0.frequency) < abs(peakFrequency - $1.frequency)
        }?.name ?? "A minor"
    }

    private static func frequencyMagnitudes(
        samples: [Float],
        sampleRate: Float,
        windowSize: Int
    ) -> [(frequency: Float, magnitude: Float)] {
        guard windowSize > 0 else { return [] }

        let maxBin = windowSize / 2
        let stride = max(1, maxBin / 96)
        var output: [(Float, Float)] = []

        for bin in stride(from: 1, to: maxBin, by: stride) {
            var real: Float = 0
            var imaginary: Float = 0

            for index in 0..<windowSize {
                let phase = 2.0 * Float.pi * Float(bin * index) / Float(windowSize)
                let sample = samples[index]
                real += sample * cos(phase)
                imaginary -= sample * sin(phase)
            }

            let frequency = Float(bin) * sampleRate / Float(windowSize)
            let magnitude = sqrt(real * real + imaginary * imaginary)
            output.append((frequency, magnitude))
        }

        return output
    }
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
