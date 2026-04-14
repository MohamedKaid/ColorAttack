//
//  PaywallView.swift
//  GameDev
//
//  Shown when:
//    1. Player taps Chaos or Sequence with 0 daily tries remaining
//    2. As an upsell after watching an ad to continue
//

import SwiftUI

struct PaywallView: View {

    @EnvironmentObject var store: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    let mode: GameMode          // Which mode triggered the paywall
    let triesRemaining: Int     // 0 when tries are exhausted

    @State private var isPurchasingNoAds   = false
    @State private var isPurchasingPremium = false
    @State private var isRestoring         = false
    @State private var showError           = false
    @State private var errorMessage        = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image(systemName: triesRemaining == 0 ? "lock.fill" : "crown.fill")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FF6B35")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.top, 32)

                        if triesRemaining == 0 {
                            Text("Daily Limit Reached")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("You've used all 3 free \(mode.title) plays for today.\nCome back tomorrow — or unlock unlimited access!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        } else {
                            Text("Unlock \(mode.title) Mode")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("Get unlimited access to all premium modes with no interruptions.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }

                    // MARK: - Feature Comparison
                    VStack(spacing: 0) {
                        featureRow(icon: "checkmark.circle.fill", color: .green,
                                   text: "Classic & Rapid — always free")
                        Divider().background(Color.white.opacity(0.1))
                        featureRow(icon: triesRemaining > 0 ? "checkmark.circle.fill" : "clock.fill",
                                   color: triesRemaining > 0 ? .green : .orange,
                                   text: "Chaos & Sequence — 3 plays/day free")
                        Divider().background(Color.white.opacity(0.1))
                        featureRow(icon: "infinity", color: Color(hex: "FFD700"),
                                   text: "Premium: unlimited Chaos & Sequence",
                                   isPremium: true)
                        Divider().background(Color.white.opacity(0.1))
                        featureRow(icon: "xmark.circle.fill", color: Color(hex: "FF6B35"),
                                   text: "No Ads: removes all banner & rewarded ads",
                                   isPremium: true)
                    }
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // MARK: - Purchase Buttons
                    VStack(spacing: 12) {

                        // Premium — highlighted
                        purchaseButton(
                            title: "Go Premium",
                            subtitle: "Unlimited modes + No Ads",
                            price: store.premiumPrice,
                            gradient: [Color(hex: "FFD700"), Color(hex: "FF6B35")],
                            isLoading: isPurchasingPremium
                        ) {
                            isPurchasingPremium = true
                            Task {
                                await store.purchasePremium()
                                isPurchasingPremium = false
                                if store.hasPremium { dismiss() }
                            }
                        }

                        // No Ads only
                        purchaseButton(
                            title: "Remove Ads",
                            subtitle: "No banners or rewarded ads",
                            price: store.noAdsPrice,
                            gradient: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                            isLoading: isPurchasingNoAds
                        ) {
                            isPurchasingNoAds = true
                            Task {
                                await store.purchaseNoAds()
                                isPurchasingNoAds = false
                                if store.hasNoAds { dismiss() }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Restore & Dismiss
                    VStack(spacing: 10) {
                        Button {
                            isRestoring = true
                            Task {
                                await store.restoreEntitlements()
                                isRestoring = false
                                if store.hasPremium || store.hasNoAds { dismiss() }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isRestoring {
                                    ProgressView().tint(.white)
                                }
                                Text(isRestoring ? "Restoring…" : "Restore Purchases")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .disabled(isRestoring)

                        Button("Maybe Later") { dismiss() }
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private func featureRow(icon: String, color: Color, text: String, isPremium: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: isPremium ? .semibold : .regular))
                .foregroundColor(isPremium ? .white : .white.opacity(0.75))
            Spacer()
            if isPremium {
                Text("PRO")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "FFD700"))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func purchaseButton(
        title: String,
        subtitle: String,
        price: String,
        gradient: [Color],
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(price)
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 10, y: 4)
        }
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    PaywallView(mode: .chaos, triesRemaining: 0)
        .environmentObject(StoreKitManager())
}

