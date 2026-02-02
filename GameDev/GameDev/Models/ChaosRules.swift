//
//  ChaosRules.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ChaosRules: ModeRules, TimingRules {

    // Track required targets for the round
    private let shapes = GameShape.allCases

    func makeGrid(
        from pool: [GameColor],
        cardsPerGrid: Int,
        round: Int,
        score: Int
    ) -> [GameColor] {
        Array(pool.shuffled().prefix(6))
    }

    func makePrompt(
        round: Int,
        score: Int,
        grid: [GameColor],
        pool: [GameColor]
    ) -> (prompt: Prompt, switchOn: Bool) {

        let color = grid.randomElement()!.name.uppercased()
        let shape = shapes.randomElement()!.rawValue.uppercased()

        //  Step 3: Reduce DON'T TAP early
        let allowDontTap = round >= 5

        let colorDontTap = allowDontTap && Bool.random()
        let shapeDontTap = allowDontTap && Bool.random()

        let colorLine = colorDontTap
            ? "COLOR: DON'T TAP \(color)"
            : "COLOR: TAP \(color)"

        let shapeLine = shapeDontTap
            ? "SHAPE: DON'T TAP \(shape)"
            : "SHAPE: TAP \(shape)"

        let text =
        """
        \(colorLine)
        \(shapeLine)
        """

        return (Prompt(text: text), false)
    }

    func isCorrect(
        action: PlayerAction,
        prompt: Prompt,
        grid: [GameColor],
        switchOn: Bool,
        round: Int,
        score: Int
    ) -> Bool {

        let text = prompt.text

        switch action {

        case .colorTap(let tappedColor):
            if text.contains("COLOR: DON'T TAP \(tappedColor.name.uppercased())") {
                return false
            }
            if text.contains("COLOR: TAP") {
                return text.contains(tappedColor.name.uppercased())
            }
            return true

        case .shapeTap(let tappedShape):
            if text.contains("SHAPE: DON'T TAP \(tappedShape.rawValue.uppercased())") {
                return false
            }
            if text.contains("SHAPE: TAP") {
                return text.contains(tappedShape.rawValue.uppercased())
            }
            return true

        case .noTap:
            let colorDontTap = text.contains("COLOR: DON'T TAP")
            let shapeDontTap = text.contains("SHAPE: DON'T TAP")
            return colorDontTap && shapeDontTap
        }
    }

    func scoreDelta(isCorrect: Bool) -> Int {
        isCorrect ? 20 : 0
    }

    func shouldReshuffle(round: Int, score: Int) -> Bool {
        true
    }
    
    func tapTimeLimit(for round: Int) -> TimeInterval {
        let start: TimeInterval = 4.5     // much slower start
        let min: TimeInterval = 1.8       // never too fast
        let decayEvery: Int = 6            // slows down less often
        let decayAmount: TimeInterval = 0.2

        let steps = round / decayEvery
        let time = start - (Double(steps) * decayAmount)

        return max(time, min)
    }
}
