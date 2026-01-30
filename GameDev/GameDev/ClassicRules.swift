//
//  ClassicRules.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 1/28/26.
//

//  Classic mode rulebook:
//  - Starts simple (tap color)
//  - Introduces "DON'T TAP"
//  - Increases grid size
//  - Speeds up over time
//

import SwiftUI

struct ClassicRules: ModeRules {
    
    // How many rounds before we add more colors
    private let difficultyStep = 15
    private let firstStep = 4
    
    /// Rounds after which "DON'T TAP" can appear
    private let switchStartRound = 5
    
    // Probability of it switching
    private let switchChance: Double = 0.3
    
    /// Chance that a "DON'T TAP" prompt uses a color NOT on the grid
    private let offGridChance: Double = 0.3

    /// Minimum round before off-grid prompts are allowed
    private let offGridStartRound = 1000000000
    
    // MARK: - Grid
    
    func makeGrid(
        from pool: [GameColor],
        cardsPerGrid: Int,
        round: Int,
        score: Int
    ) -> [GameColor] {
        
        let gridSize: Int
        
        switch round {
        case 0..<firstStep:
            gridSize = 3
        case firstStep..<(difficultyStep):
            gridSize = 6
        default:
            gridSize = 9
        }
        
        return Array(pool.shuffled().prefix(gridSize))
    }
    
    // MARK: - Prompt
    
    func makePrompt(
        round: Int,
        score: Int,
        grid: [GameColor],
        pool: [GameColor]
    ) -> (prompt: Prompt, switchOn: Bool) {

        let canSwitch = round >= switchStartRound
        let switchOn = canSwitch && Double.random(in: 0...1) < switchChance

        let useOffGrid =
            switchOn &&
            round >= offGridStartRound &&
            Double.random(in: 0...1) < offGridChance

        let targetName: String

        if useOffGrid {
            // Pick a color NOT in the grid
            let gridNames = Set(grid.map { $0.name })
            let offGridColors = pool.filter { !gridNames.contains($0.name) }
            targetName = offGridColors.randomElement()?.name ?? grid.randomElement()?.name ?? "?"
        } else {
            // Normal on-grid target
            targetName = grid.randomElement()?.name ?? "?"
        }

        let text = switchOn
            ? "DON'T TAP \(targetName.uppercased())"
            : "TAP \(targetName.uppercased())"

        return (Prompt(text: text), switchOn)
    }
    
    // MARK: - Correctness
    
    func isCorrect(
        action: PlayerAction,
        prompt: Prompt,
        grid: [GameColor],
        switchOn: Bool,
        round: Int,
        score: Int
    ) -> Bool {
        
        guard let targetName = extractColorName(from: prompt.text) else {
            return false
        }
        
        switch action {
            
        case .tap(let tappedColor):
            if switchOn {
                // DON'T TAP target
                return tappedColor.name != targetName
            } else {
                // TAP target
                return tappedColor.name == targetName
            }
            
        case .noTap:
            // Correct ONLY if instruction was DON'T TAP
            return switchOn
        }
    }
    
    // MARK: - Scoring
    
    func scoreDelta(isCorrect: Bool) -> Int {
        isCorrect ? 10 : 0
    }
    
    // MARK: - Grid reshuffle logic
    
    func shouldReshuffle(round: Int, score: Int) -> Bool {
        switch round {
        case 0..<10:
            return round % 8 == 0   // early: very stable
        case 10..<20:
            return round % 4 == 0
        default:
            return round % 2 == 0   // late game: more chaos
        }
    }
    
    // MARK: - Helpers
    
    private func extractColorName(from prompt: String) -> String? {
        prompt
            .replacingOccurrences(of: "DON'T TAP ", with: "")
            .replacingOccurrences(of: "TAP ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
    // MARK: - Speed control
    
    func tapTimeLimit(for round: Int) -> TimeInterval {
        let start: TimeInterval = 2.5   // slower start
        let min: TimeInterval = 0.8      // more forgiving minimum
        let decayEvery: Int = 8          // slow down every N rounds
        let decayAmount: TimeInterval = 0.1
        
        let steps = round / decayEvery
        let time = start - (Double(steps) * decayAmount)
        return max(time, min)
    }
}
