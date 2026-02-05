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

final class ClassicRules: ModeRules, TimingRules{
    
    // How many rounds before we add more colors
    private let difficultyStep = 15
    private let firstStep = 4
    
    //Rounds after which "DON'T TAP" can appear
    private let switchStartRound = 5
    
    // Probability of it switching
    private let switchChance: Double = 0.3
    
    // Round when Stroop effect starts
    private let stroopStartRound = 15

    // Chance (0–1) that Stroop is applied once unlocked
    private let stroopChance: Double = 0.4
    
    // Chance that a "DON'T TAP" prompt uses a color NOT on the grid
    private let offGridChance: Double = 0.3

    //Minimum round before off-grid prompts are allowed
    private let offGridStartRound = 1000000000
    
    private var lastTargetName: String? = nil
    
    // Creating grid
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
    
    // Creating Prompt
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

        var candidates: [String]

        if useOffGrid {
            // Pick a color NOT in the grid
            let gridNames = Set(grid.map { $0.name })
            candidates = pool
                .map { $0.name }
                .filter { !gridNames.contains($0) }
        } else {
            // Normal on-grid candidates
            candidates = grid.map { $0.name }
        }

        if let last = lastTargetName, candidates.count > 1 {
            candidates.removeAll { $0 == last }
        }

        let targetName = candidates.randomElement() ?? "?"
        lastTargetName = targetName   

        let text = switchOn
            ? "DON'T TAP \(targetName.uppercased())"
            : "TAP \(targetName.uppercased())"

        var displayColor: GameColor? = nil

        if round >= stroopStartRound,
           Double.random(in: 0...1) < stroopChance {

            // Pick a DIFFERENT color than the target
            let otherColors = pool.filter { $0.name.uppercased() != targetName.uppercased() }
            displayColor = otherColors.randomElement()
        }

        return (
            Prompt(text: text, displayColor: displayColor),
            switchOn
        )
    }
    
    // Determines whether its correct based on the action
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

        case .colorTap(let tappedColor):
            if switchOn {
                return tappedColor.name != targetName
            } else {
                return tappedColor.name == targetName
            }

        case .noTap:
            return switchOn

        case .shapeTap:
            return false
        }
    }
    
    // Scoring System
    func scoreDelta(isCorrect: Bool) -> Int {
        isCorrect ? 10 : 0
    }
    
    // Reshuffles the cards more often as you advance
    func shouldReshuffle(round: Int, score: Int) -> Bool {
        switch round {
        case 0..<10:
            return round % 8 == 0
        case 10..<20:
            return round % 4 == 0
        default:
            return round % 2 == 0
        }
    }
    
    // Getting color name from prompt
    private func extractColorName(from prompt: String) -> String? {
        prompt
            .replacingOccurrences(of: "DON'T TAP ", with: "")
            .replacingOccurrences(of: "TAP ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
    
    // Limit for tapping(gets lower as you go)
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
