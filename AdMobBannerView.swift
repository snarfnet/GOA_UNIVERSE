import GoogleMobileAds
import SwiftUI
import UIKit

struct AdMobBannerView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-9404799280370656/6826864464"

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: largeAnchoredAdaptiveBanner(width: 320))
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
