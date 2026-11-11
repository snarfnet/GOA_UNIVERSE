import Foundation
@main struct RenderSong {
    static func main() throws {
        try GoaSong.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
        print("Rendered Solstice Spiral: 180 seconds, 144 BPM, 108 bars")
    }
}
