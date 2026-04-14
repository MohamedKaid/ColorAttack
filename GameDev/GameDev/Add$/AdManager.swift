//
//  AdManager.swift
//  GameDev
//
//  Wraps Google AdMob rewarded ads and banner ad state.
//  ⚠️  Replace the placeholder ad unit IDs with your real AdMob IDs before release.
//      Test IDs are provided so you can run the app during development.
//

import Foundation
import GoogleMobileAds

// MARK: - Ad Unit IDs
// Swap these for your real AdMob ad unit IDs before submitting to the App Store.
private enum AdUnitID {
    /// Test rewarded ad ID (Google official test ID)
    static let rewarded = "ca-app-pub-3940256099942544/1712485313"
    /// Test banner ad ID (Google official test ID)
    static let banner   = "ca-app-pub-3940256099942544/2934735716"
}

// MARK: - AdManager

@MainActor
final class AdManager: NSObject, ObservableObject {

    static let shared = AdManager()

    // MARK: - State
    @Published private(set) var isRewardedAdReady: Bool = false
    @Published private(set) var didEarnReward: Bool = false

    private var rewardedAd: GADRewardedAd?
    private var rewardCompletion: (() -> Void)?

    // MARK: - Init
    private override init() {
        super.init()
        loadRewardedAd()
    }

    // MARK: - Rewarded Ad

    func loadRewardedAd() {
        isRewardedAdReady = false
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: AdUnitID.rewarded, request: request) { [weak self] ad, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    print("AdManager: Rewarded ad failed to load — \(error.localizedDescription)")
                    self.isRewardedAdReady = false
                    return
                }
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isRewardedAdReady = true
                print("AdManager: Rewarded ad loaded ✓")
            }
        }
    }

    /// Present the rewarded ad. `onRewardEarned` is called when the user completes the ad.
    func showRewardedAd(from viewController: UIViewController, onRewardEarned: @escaping () -> Void) {
        guard let ad = rewardedAd else {
            print("AdManager: No rewarded ad ready — granting reward anyway (fallback)")
            onRewardEarned()
            return
        }
        rewardCompletion = onRewardEarned
        didEarnReward = false
        ad.present(fromRootViewController: viewController) { [weak self] in
            // This block fires when reward is earned (user watched enough of the ad)
            self?.didEarnReward = true
        }
    }

    // MARK: - Banner Ad Unit ID (read by BannerAdView)
    var bannerAdUnitID: String { AdUnitID.banner }
}

// MARK: - GADFullScreenContentDelegate
extension AdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            if self.didEarnReward {
                self.rewardCompletion?()
            }
            self.rewardCompletion = nil
            self.rewardedAd = nil
            self.isRewardedAdReady = false
            self.loadRewardedAd() // Pre-load next ad
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("AdManager: Failed to present — \(error.localizedDescription)")
            // Fallback: grant reward anyway so player isn't punished for ad failure
            self.rewardCompletion?()
            self.rewardCompletion = nil
            self.loadRewardedAd()
        }
    }
}

// MARK: - BannerAdView (UIViewRepresentable)

import SwiftUI

/// Drop this into any SwiftUI view to show a banner.
/// Automatically hidden when `storeKit.adsRemoved` is true.
struct BannerAdView: UIViewRepresentable {

    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.topMostViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - UIApplication helper (reuse existing or add here)
private extension UIApplication {
    var topMostViewController: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
