//
//  GameEngine.swift
//  GameDev
//
//  Universal game engine for all modes
//

import SwiftUI
import Combine
import GameKit

// Mode configuration (required leaderboardID for each mode)
struct ModeConfig {
    var cardsPerGrid: Int
    var tapTimeLimit: TimeInterval
    var usesLives: Bool
    var totalGameTimeLimit: TimeInterval?
    var leaderboardID: String

    init(
        cardsPerGrid: Int = 6,
        tapTimeLimit: TimeInterval = 1.0,
        usesLives: Bool = true,
        totalGameTimeLimit: TimeInterval? = nil,
        leaderboardID: String
    ) {
        self.cardsPerGrid = cardsPerGrid
        self.tapTimeLimit = tapTimeLimit
        self.usesLives = usesLives
        self.totalGameTimeLimit = totalGameTimeLimit
        self.leaderboardID = leaderboardID
    }
}

// A player's action in a round
enum PlayerAction {
    case noTap
    case colorTap(GameColor)
    case shapeTap(GameShape)
}

// Prompt shown to the player
struct Prompt {
    var text: String
    var displayColor: GameColor? = nil
}

// Optional: rules can dynamically change tap time by round
protocol TimingRules {
    func tapTimeLimit(for round: Int) -> TimeInterval
}

// Rules contract for each mode
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

@MainActor
final class GameEngine: ObservableObject {

    let lives: Lives
    let colorPool: [GameColor]
    let config: ModeConfig
    let rules: (any ModeRules)?

    // Prevent submitting the same run multiple times
    private var didSubmitScore = false

    // State the UI reads
    @Published private(set) var gridColors: [GameColor] = []
    @Published private(set) var promptText: String = ""
    @Published private(set) var switchOn: Bool = false
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var score: Int = 0
    @Published private(set) var round: Int = 0
    @Published private(set) var remainingTapTime: TimeInterval = 0
    @Published private(set) var gridShapes: [GameShape] = []
    @Published private(set) var shouldShuffleShapes: Bool = false
    @Published private(set) var remainingGameTime: TimeInterval? = nil
    @Published private(set) var currentPrompt = Prompt(text: "?")

    // Internal round state
    private var promptTask: Task<Void, Never>?
    private var gameTimerTask: Task<Void, Never>?
    private var requiredActionsThisRound: Int = 1
    private var actionsTakenThisRound: Int = 0
    private var allActionsCorrectThisRound: Bool = true

    init(
        lives: Lives,
        colorPool: [GameColor],
        config: ModeConfig,
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

    func start() {
        stop()

        didSubmitScore = false
        lives.reset()
        score = 0
        round = 0
        isGameOver = false
        remainingGameTime = config.totalGameTimeLimit

        rebuildGridIfNeeded(force: true)
        startGameTimerIfNeeded()
        nextRound()
    }

    func stop() {
        promptTask?.cancel()
        promptTask = nil
        remainingTapTime = 0

        gameTimerTask?.cancel()
        gameTimerTask = nil
    }

    func restart() {
        isGameOver = true
    }


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

        allActionsCorrectThisRound = allActionsCorrectThisRound && correct
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
            endGame()
        } else {
            proceed()
        }
    }

    private func endGame() {
        guard !isGameOver else { return }
        isGameOver = true
        stop()
        submitScoreIfNeeded()
    }

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
            endGame()
            return
        }

        round += 1
        actionsTakenThisRound = 0
        allActionsCorrectThisRound = true

        // Chaos requires two actions per round
        requiredActionsThisRound = (rules is ChaosRules) ? 2 : 1

        rebuildGridIfNeeded(force: false)

        // Chaos spatial difficulty (optional)
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
        } else {
            currentPrompt = Prompt(text: gridColors.randomElement()?.name ?? "?")
            promptText = currentPrompt.text
            switchOn = Bool.random()
        }

        startPromptTimer()
    }

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
                    endGame()
                    return
                }

                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private func proceed() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            nextRound()
        }
    }

    private func submitScoreIfNeeded() {
        guard !didSubmitScore else { return }

        guard GKLocalPlayer.local.isAuthenticated else {
            print("Game Center not authenticated (will not submit yet).")
            return
        }

        didSubmitScore = true

        let leaderboardID = config.leaderboardID
        print("Submitting score \(score) to \(leaderboardID)")

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("✅ Score submitted:", score)
            } catch {
                print("❌ Score submit failed:", error.localizedDescription)
                // optional: allow retry if it failed
                didSubmitScore = false
            }
        }
    }
}
