//
//  RapidRules.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

struct RapidRules: ModeRules {

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
        let called = grid.randomElement()?.name ?? "?"
        return (Prompt(text: called), false)
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
        case .noTap:
            return false
        case .tap(let tappedColor):
            return tappedColor.name == prompt.text
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
