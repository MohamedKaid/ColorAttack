//
//  RapidRules.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

final class RapidRules: ModeRules {

    private var lastTargetName: String? = nil
    
    // Rapid: always a fixed grid (6 cards from config), no special reshuffle logic
    func makeGrid(from pool: [GameColor], cardsPerGrid: Int, round: Int, score: Int) -> [GameColor] {
        Array(pool.shuffled().prefix(cardsPerGrid))
    }

    // Rapid: prompt is always an on-grid color. Switch is effectively "off" (not used).
    func makePrompt(
        round: Int,
        score: Int,
        grid: [GameColor],
        pool: [GameColor]
    ) -> (prompt: Prompt, switchOn: Bool) {

        var candidates = grid.map { $0.name }

        // Remove last target if possible
        if let last = lastTargetName, candidates.count > 1 {
            candidates.removeAll { $0 == last }
        }

        let chosen = candidates.randomElement() ?? "?"
        lastTargetName = chosen

        return (Prompt(text: chosen), false)
    }

    // Rapid: correct = tap the called color. Timeout/noTap = wrong.
    func isCorrect(
        action: PlayerAction,
        prompt: Prompt,
        grid: [GameColor],
        switchOn: Bool,
        round: Int,
        score: Int
    ) -> Bool {
        switch action {
        case .colorTap(let tappedColor):
            return tappedColor.name == prompt.text
        case .noTap:
            return false
        case .shapeTap:
            return false
        }
    }

    // Rapid scoring: +10 correct, -5 wrong
    func scoreDelta(isCorrect: Bool) -> Int {
        isCorrect ? 10 : -5
    }

    // Rapid: no reshuffle rule needed (keep false for now)
    func shouldReshuffle(round: Int, score: Int) -> Bool {
        false
    }
}
