//
//  SequenceRules.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 3/30/26.
//

import SwiftUI

// Represents a single item in the sequence — either a color or a shape
enum SequenceItem: Equatable {
    case color(GameColor)
    case shape(GameShape)

    var displayName: String {
        switch self {
        case .color(let c): return c.name.uppercased()
        case .shape(let s): return s.rawValue.uppercased()
        }
    }
}

// A unified grid item — either a color card or a shape card
// Named SequenceGridItem to avoid conflict with SwiftUI's GridItem
enum SequenceGridItem: Identifiable, Equatable {
    case color(GameColor)
    case shape(GameShape)

    var id: String {
        switch self {
        case .color(let c): return "color_\(c.name)"
        case .shape(let s): return "shape_\(s.rawValue)"
        }
    }
}

final class SequenceRules: ModeRules {

    private let roundsPerLengthIncrease = 3
    private let startingLength = 3

    private(set) var currentSequence: [SequenceItem] = []
    private(set) var sequenceIndex: Int = 0
    private(set) var hadMistakeThisRound: Bool = false

    // MARK: - ModeRules (unused stubs — sequence manages its own loop)

    func makeGrid(from pool: [GameColor], cardsPerGrid: Int, round: Int, score: Int) -> [GameColor] {
        return []
    }

    func makePrompt(round: Int, score: Int, grid: [GameColor], pool: [GameColor]) -> (prompt: Prompt, switchOn: Bool) {
        return (Prompt(text: ""), false)
    }

    func isCorrect(action: PlayerAction, prompt: Prompt, grid: [GameColor], switchOn: Bool, round: Int, score: Int) -> Bool {
        return false
    }

    func scoreDelta(isCorrect: Bool) -> Int {
        return 0
    }

    func shouldReshuffle(round: Int, score: Int) -> Bool {
        return true
    }

    // MARK: - Sequence Logic

    func buildSequenceRound(pool: [GameColor], round: Int) -> (grid: [SequenceGridItem], sequence: [SequenceItem]) {
        let allItems: [SequenceGridItem] = pool.map { .color($0) } + GameShape.allCases.map { .shape($0) }

        let grid = Array(allItems.shuffled().prefix(12))

        let length = min(startingLength + (round / roundsPerLengthIncrease), grid.count)

        let sequenceItems: [SequenceItem] = Array(grid.shuffled().prefix(length)).map { item in
            switch item {
            case .color(let c): return .color(c)
            case .shape(let s): return .shape(s)
            }
        }

        currentSequence = sequenceItems
        sequenceIndex = 0
        hadMistakeThisRound = false

        return (grid, sequenceItems)
    }

    func checkTap(_ tappedItem: SequenceGridItem) -> Bool {
        guard sequenceIndex < currentSequence.count else { return false }

        let expected = currentSequence[sequenceIndex]

        let correct: Bool
        switch (tappedItem, expected) {
        case (.color(let tapped), .color(let exp)):
            correct = tapped.name == exp.name
        case (.shape(let tapped), .shape(let exp)):
            correct = tapped == exp
        default:
            correct = false
        }

        if correct {
            sequenceIndex += 1
        } else {
            hadMistakeThisRound = true
        }

        return correct
    }

    var isSequenceComplete: Bool {
        sequenceIndex >= currentSequence.count
    }
}
