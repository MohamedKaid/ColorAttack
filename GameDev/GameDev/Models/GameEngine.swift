//
//  GameEngine.swift
//  GameDev
//
//  Universal game engine for all modes
//

import SwiftUI
import Combine

// MARK: - Universal Mode Types

/// Pure "numbers + limits" for a mode (no logic).
struct ModeConfig {
    var cardsPerGrid: Int
    var tapTimeLimit: TimeInterval

    /// Does this mode use lives? (Rapid = false)
    var usesLives: Bool

    /// Total game time limit in seconds (Rapid = 120, others = nil)
    var totalGameTimeLimit: TimeInterval?

    init(
        cardsPerGrid: Int = 6,
        tapTimeLimit: TimeInterval = 1.0,
        usesLives: Bool = true,
        totalGameTimeLimit: TimeInterval? = nil
    ) {
        self.cardsPerGrid = cardsPerGrid
        self.tapTimeLimit = tapTimeLimit
        self.usesLives = usesLives
        self.totalGameTimeLimit = totalGameTimeLimit
    }
}

/// What the player did this round (generic).
enum PlayerAction {
    case noTap

    // Classic / Rapid
    case colorTap(GameColor)

    // Chaos
    case shapeTap(GameShape)
}

/// What the engine is asking the player to do (generic).
struct Prompt {
    var text: String
    var displayColor: GameColor? = nil
}

protocol TimingRules {
    func tapTimeLimit(for round: Int) -> TimeInterval
}

/// Behavior contract: each mode can decide prompts + correctness + scoring + reshuffle.
protocol ModeRules {
    func makeGrid(from pool: [GameColor], cardsPerGrid: Int, round: Int, score: Int) -> [GameColor]

    func makePrompt(
        round: Int,
        score: Int,
        grid: [GameColor],
        pool: [GameColor]
    ) -> (prompt: Prompt, switchOn: Bool)

    func isCorrect(
        action: PlayerAction,
        prompt: Prompt,
        grid: [GameColor],
        switchOn: Bool,
        round: Int,
        score: Int
    ) -> Bool

    func scoreDelta(isCorrect: Bool) -> Int

    func shouldReshuffle(round: Int, score: Int) -> Bool
}

// MARK: - Game Engine

@MainActor
final class GameEngine: ObservableObject {

    // MARK: - Dependencies
    let lives: Lives
    let colorPool: [GameColor]

    // MARK: - Mode Plug-ins
    let config: ModeConfig
    let rules: (any ModeRules)?

    // MARK: - Game State (UI reads these)
    @Published private(set) var gridColors: [GameColor] = []
    @Published private(set) var promptText: String = ""
    @Published private(set) var switchOn: Bool = false
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var score: Int = 0
    @Published private(set) var round: Int = 0
    @Published private(set) var remainingTapTime: TimeInterval = 0
    @Published private(set) var gridShapes: [GameShape] = []
    @Published private(set) var shouldShuffleShapes: Bool = false


    /// For timed modes (Rapid): counts down to 0. Nil means "not timed".
    @Published private(set) var remainingGameTime: TimeInterval? = nil

    // MARK: - Internal State
    private var hasRespondedThisRound = false
    private var promptTask: Task<Void, Never>?
    private var gameTimerTask: Task<Void, Never>?
    @Published private(set) var currentPrompt = Prompt(text: "?")
    // Chaos multi-action support
    private var requiredActionsThisRound: Int = 1
    private var actionsTakenThisRound: Int = 0
    private var allActionsCorrectThisRound: Bool = true

    // MARK: - Init
    init(
        lives: Lives,
        colorPool: [GameColor],
        config: ModeConfig = ModeConfig(),
        rules: (any ModeRules)? = nil
    ) {
        self.lives = lives
        self.colorPool = colorPool
        self.config = config
        self.rules = rules
    }

    deinit {
        promptTask?.cancel()
        gameTimerTask?.cancel()
    }

    // MARK: - Lifecycle

    func start() {
        stop()

        // Reset state
        lives.reset()
        score = 0
        round = 0
        isGameOver = false
        remainingGameTime = config.totalGameTimeLimit

        // Build initial grid + kick off timers
        rebuildGridIfNeeded(force: true)
        startGameTimerIfNeeded()
        nextRound()
    }

    func stop() {
        promptTask?.cancel()
        promptTask = nil

        gameTimerTask?.cancel()
        gameTimerTask = nil
    }

    func restart() {
        start()
    }

    // MARK: - Player Input

//    func handleTap(on color: GameColor) {
//        guard !isGameOver else { return }
//        guard !hasRespondedThisRound else { return }
//
//        hasRespondedThisRound = true
//        stopPromptTimerOnly()
//
//        let action: PlayerAction = .tap(color)
//
//        if let rules {
//            let correct = rules.isCorrect(
//                action: action,
//                prompt: currentPrompt,
//                grid: gridColors,
//                switchOn: switchOn,
//                round: round,
//                score: score
//            )
//
//            score += rules.scoreDelta(isCorrect: correct)
//
//            if !correct && config.usesLives {
//                lives.lose()
//            }
//        } else {
//            // TEMP fallback (if you ever run without rules)
//            score += 10
//        }
//
//        if config.usesLives, lives.isEmpty {
//            isGameOver = true
//            stop()
//            return
//        }
//
//        proceed()
//    }
    
    func handleTap(action: PlayerAction) {
        guard !isGameOver else { return }

        let correct: Bool

        if let rules {
            correct = rules.isCorrect(
                action: action,
                prompt: currentPrompt,
                grid: gridColors,
                switchOn: switchOn,
                round: round,
                score: score
            )
        } else {
            correct = true
        }

        allActionsCorrectThisRound =
            allActionsCorrectThisRound && correct

        actionsTakenThisRound += 1

        if actionsTakenThisRound >= requiredActionsThisRound {
            finalizeRound()
        }
    }
    
    private func finalizeRound() {
        stopPromptTimerOnly()

        if let rules {
            score += rules.scoreDelta(isCorrect: allActionsCorrectThisRound)

            if !allActionsCorrectThisRound && config.usesLives {
                lives.lose()
            }
        }

        if config.usesLives, lives.isEmpty {
            isGameOver = true
            stop()
        } else {
            proceed()
        }
    }

    // MARK: - Core Loop

    private func rebuildGridIfNeeded(force: Bool) {
        if force {
            buildGrid()
            return
        }

        if let rules, rules.shouldReshuffle(round: round, score: score) {
            buildGrid()
        }
    }

    private func buildGrid() {
        if let rules {
            gridColors = rules.makeGrid(
                from: colorPool,
                cardsPerGrid: config.cardsPerGrid,
                round: round,
                score: score
            )
        } else {
            gridColors = Array(colorPool.shuffled().prefix(config.cardsPerGrid))
        }
    }

    private func nextRound() {
        guard !isGameOver else { return }

        if config.usesLives, lives.isEmpty {
            isGameOver = true
            stop()
            return
        }

        round += 1
        hasRespondedThisRound = false
        actionsTakenThisRound = 0
        allActionsCorrectThisRound = true

        // Chaos requires two actions per round
        requiredActionsThisRound = rules is ChaosRules ? 2 : 1

        rebuildGridIfNeeded(force: false)

        var lastPromptText: String = ""
        
        // Chaos spatial difficulty
        if rules is ChaosRules {
            switch round {
            case 0..<10:
                shouldShuffleShapes = false
            case 10..<20:
                shouldShuffleShapes = round % 3 == 0
            default:
                shouldShuffleShapes = true
            }

            if shouldShuffleShapes {
                gridShapes = GameShape.allCases.shuffled()
            } else if gridShapes.isEmpty {
                gridShapes = GameShape.allCases
            }
        }

        if let rules {
            let result = rules.makePrompt(round: round, score: score, grid: gridColors, pool: colorPool)
            currentPrompt = result.prompt
            promptText = result.prompt.text
            switchOn = result.switchOn

            lastPromptText = currentPrompt.text
        } else {
            var newText = gridColors.randomElement()?.name ?? "?"
            
            while newText != lastPromptText && gridColors.count > 1 {
                newText = gridColors.randomElement()?.name ?? "?"
            }
            currentPrompt = Prompt(text: newText)
            promptText = newText
            switchOn = Bool.random()
            lastPromptText = newText
        }


        startPromptTimer()
    }

    // MARK: - Prompt Timer (tap time limit)

    private func startPromptTimer() {
        stopPromptTimerOnly()

        let timeLimit: TimeInterval

        if let timingRules = rules as? TimingRules {
            timeLimit = timingRules.tapTimeLimit(for: round)
        } else {
            timeLimit = config.tapTimeLimit
        }

        remainingTapTime = timeLimit

        promptTask = Task { @MainActor in
            let start = Date()

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, timeLimit - elapsed)
                remainingTapTime = remaining

                if remaining <= 0 {
                    handleTimeout()
                    return
                }

                // update ~10x per second (smooth but cheap)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private func stopPromptTimerOnly() {
        promptTask?.cancel()
        promptTask = nil
        remainingTapTime = 0
    }

    private func handleTimeout() {
        guard !isGameOver else { return }

        let missingActions = requiredActionsThisRound - actionsTakenThisRound

        if missingActions > 0 {
            allActionsCorrectThisRound = false
            actionsTakenThisRound = requiredActionsThisRound
            finalizeRound()
        }
    }
    // MARK: - Game Timer (total time limit)

    private func startGameTimerIfNeeded() {
        gameTimerTask?.cancel()
        gameTimerTask = nil

        guard let limit = config.totalGameTimeLimit else {
            remainingGameTime = nil
            return
        }

        remainingGameTime = limit

        gameTimerTask = Task { @MainActor in
            let start = Date()

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, limit - elapsed)
                remainingGameTime = remaining

                if remaining <= 0 {
                    isGameOver = true
                    stop()
                    return
                }

                // update twice per second (smooth enough for UI)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    // MARK: - Round Advance

    private func proceed() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            nextRound()
        }
    }
}
