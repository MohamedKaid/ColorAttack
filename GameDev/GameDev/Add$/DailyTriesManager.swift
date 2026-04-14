//
//  DailyTriesManager.swift
//  GameDev
//
//  Tracks free daily play counts for premium-gated modes (Chaos & Sequence).
//  Resets automatically at midnight. Premium users bypass all limits.
//

import Foundation
import Combine

@MainActor
final class DailyTriesManager: ObservableObject {

    // MARK: - Config
    static let dailyLimit = 3

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let chaosCount   = "dailyTries.chaos.count"
        static let sequenceCount = "dailyTries.sequence.count"
        static let lastResetDate = "dailyTries.lastResetDate"
    }

    // MARK: - Published
    @Published private(set) var chaosTriesUsed: Int = 0
    @Published private(set) var sequenceTriesUsed: Int = 0

    // MARK: - Computed
    var chaosTriesRemaining: Int    { max(0, Self.dailyLimit - chaosTriesUsed) }
    var sequenceTriesRemaining: Int { max(0, Self.dailyLimit - sequenceTriesUsed) }

    var canPlayChaos: Bool    { chaosTriesRemaining > 0 }
    var canPlaySequence: Bool { sequenceTriesRemaining > 0 }

    // MARK: - Init
    init() {
        resetIfNewDay()
        load()
    }

    // MARK: - Public API

    /// Call when the player starts a Chaos game (not needed for premium users — check before calling)
    func consumeChaosPlay() {
        chaosTriesUsed = min(chaosTriesUsed + 1, Self.dailyLimit)
        save()
    }

    /// Call when the player starts a Sequence game
    func consumeSequencePlay() {
        sequenceTriesUsed = min(sequenceTriesUsed + 1, Self.dailyLimit)
        save()
    }

    // MARK: - Reset Logic

    private func resetIfNewDay() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())

        if let lastReset = defaults.object(forKey: Keys.lastResetDate) as? Date {
            if lastReset < today {
                defaults.set(0, forKey: Keys.chaosCount)
                defaults.set(0, forKey: Keys.sequenceCount)
                defaults.set(today, forKey: Keys.lastResetDate)
            }
        } else {
            defaults.set(today, forKey: Keys.lastResetDate)
        }
    }

    private func load() {
        let defaults = UserDefaults.standard
        chaosTriesUsed    = defaults.integer(forKey: Keys.chaosCount)
        sequenceTriesUsed = defaults.integer(forKey: Keys.sequenceCount)
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(chaosTriesUsed,    forKey: Keys.chaosCount)
        defaults.set(sequenceTriesUsed, forKey: Keys.sequenceCount)
    }
}
