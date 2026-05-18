//
//  NotificationManager.swift
//  Color Frenzy
//
//  Handles:
//    1. Re-engagement push notifications (bring users back to play)
//    2. App Store review prompts (triggered after good game moments)
//

import UserNotifications
import StoreKit
import SwiftUI

// MARK: - Notification Manager

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    /// Call once on first launch (from GameDevApp or ContentView.onAppear)
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("Notification permission error:", error.localizedDescription)
                return
            }
            if granted {
                print("Notification permission granted.")
                Task { @MainActor in
                    self.scheduleReEngagementNotifications()
                }
            }
        }
    }

    // MARK: - Re-Engagement Notifications

    /// Schedules a cascade of re-engagement notifications.
    /// Call this every time the user opens the app so timers always reset from "now".
    func scheduleReEngagementNotifications() {
        let center = UNUserNotificationCenter.current()

        // Remove any previously scheduled ones so we don't stack up duplicates
        center.removePendingNotificationRequests(withIdentifiers: NotificationID.allCases.map(\.rawValue))

        let notifications: [(id: NotificationID, after: TimeInterval, title: String, body: String)] = [
            (
                .oneDay,
                60 * 60 * 24,           // 24 hours
                "Your streak is waiting 🎮",
                "Can you beat your high score today? Color Frenzy is ready when you are."
            ),
            (
                .threeDays,
                60 * 60 * 24 * 3,       // 3 days
                "It's been a while… 👀",
                "The leaderboard has shifted. Come see where you stand!"
            ),
            (
                .sevenDays,
                60 * 60 * 24 * 7,       // 7 days
                "Miss the chaos? 🌪️",
                "New high scores are being set. Jump back in and reclaim your spot!"
            ),
            (
                .fourteenDays,
                60 * 60 * 24 * 14,      // 14 days
                "Color Frenzy misses you 🔥",
                "It's been two weeks! Your fastest reflexes are waiting to be tested again."
            ),
        ]

        for item in notifications {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: item.after,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: item.id.rawValue,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    print("Failed to schedule \(item.id.rawValue):", error.localizedDescription)
                }
            }
        }

        print("Re-engagement notifications scheduled.")
    }

    /// Call this when the app becomes active to cancel pending re-engagement
    /// and reschedule from now (so they always count from last open).
    func handleAppForeground() {
        scheduleReEngagementNotifications()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - App Store Review

    private let sessionsKey     = "cf_session_count"
    private let lastReviewKey   = "cf_last_review_version"
    private let reviewAskedKey  = "cf_review_asked_count"

    /// Call this after a game ends with a good result.
    /// Triggers the review prompt at natural moments without spamming.
    func handleGameOver(score: Int, mode: GameMode) {
        let defaults = UserDefaults.standard

        // Increment session count
        let sessions = defaults.integer(forKey: sessionsKey) + 1
        defaults.set(sessions, forKey: sessionsKey)

        let askedCount = defaults.integer(forKey: reviewAskedKey)
        let lastReviewVersion = defaults.string(forKey: lastReviewKey) ?? ""
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

        // Don't ask more than once per app version
        guard lastReviewVersion != currentVersion else { return }

        // Don't ask more than 3 times total (Apple enforces this too but good to self-limit)
        guard askedCount < 3 else { return }

        // Trigger conditions — ask after a genuinely good moment
        let shouldPrompt: Bool
        switch mode {
        case .classic, .chaos, .sequence:
            // Ask after 5th session OR when score crosses a meaningful threshold
            shouldPrompt = sessions == 5 || sessions == 20 || score >= 30
        case .rapid:
            shouldPrompt = sessions == 5 || sessions == 20 || score >= 15
        case .frenzy:
            shouldPrompt = sessions == 5 || sessions == 20 || score >= 50
        }

        guard shouldPrompt else { return }

        // Small delay so the game-over screen settles first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                defaults.set(currentVersion, forKey: self.lastReviewKey)
                defaults.set(askedCount + 1, forKey: self.reviewAskedKey)
            }
        }
    }
}

// MARK: - Notification IDs

private enum NotificationID: String, CaseIterable {
    case oneDay      = "cf.reengagement.1day"
    case threeDays   = "cf.reengagement.3days"
    case sevenDays   = "cf.reengagement.7days"
    case fourteenDays = "cf.reengagement.14days"
}
