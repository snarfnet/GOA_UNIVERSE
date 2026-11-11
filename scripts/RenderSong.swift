import Foundation
@main struct RenderSong {
    static func main() throws {
        let bank = CommandLine.arguments.count > 2 ? GoaSoundBank(rawValue: CommandLine.arguments[2]) ?? .classic : .classic
        try GoaSong.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), soundBank: bank)
        print("Rendered Solstice Spiral: 180 seconds, 144 BPM, 108 bars")
    }
}
