import SwiftUI
import GoogleMobileAds

@main
struct GoaUniverseApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
