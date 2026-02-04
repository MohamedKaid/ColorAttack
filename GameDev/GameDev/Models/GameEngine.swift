//
//  GameEngine.swift
//  GameDev
//
//  Universal game engine for all modes
//

import SwiftUI
import Combine


// Setting Configurations for a Mode
struct ModeConfig {
    var cardsPerGrid: Int
    var tapTimeLimit: TimeInterval
    var usesLives: Bool
    var totalGameTimeLimit: TimeInterval?
    // Default Value during initialization
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

// A player's action in a round
enum PlayerAction {
    case noTap
    case colorTap(GameColor)
    case shapeTap(GameShape)
}

// Prompt Given to the user
struct Prompt {
    var text: String
    var displayColor: GameColor? = nil
}

// The amount of time a user has to tap
protocol TimingRules {
    func tapTimeLimit(for round: Int) -> TimeInterval
}

// Format to create rules for each game
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

    // Game engine variables
    let lives: Lives
    let colorPool: [GameColor]
    let config: ModeConfig
    let rules: (any ModeRules)?

    // Individual Game variables
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

    //Internal Game variables
    private var hasRespondedThisRound = false
    private var promptTask: Task<Void, Never>?
    private var gameTimerTask: Task<Void, Never>?
    @Published private(set) var currentPrompt = Prompt(text: "?")
    // Chaos multi-action support
    private var requiredActionsThisRound: Int = 1
    private var actionsTakenThisRound: Int = 0
    private var allActionsCorrectThisRound: Bool = true

    //Initialize Game
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

    //Clear and stops giving prompts
    func stop() {
        promptTask?.cancel()
        promptTask = nil

        gameTimerTask?.cancel()
        gameTimerTask = nil
    }

    //restart game
    func restart() {
        start()
    }
    
    // Checks to see if action taken this round was correct
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
    
    // Stops timer, updates score, checks status
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

    //
    private func rebuildGridIfNeeded(force: Bool) {
        if force {
            buildGrid()
            return
        }

        if let rules, rules.shouldReshuffle(round: round, score: score) {
            buildGrid()
        }
    }

    // Build a grid
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

    // 
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

    // starts prompt timer
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

    // Reset Prompt Timer
    private func stopPromptTimerOnly() {
        promptTask?.cancel()
        promptTask = nil
        remainingTapTime = 0
    }

    // Handling a missed tap
    private func handleTimeout() {
        guard !isGameOver else { return }

        let missingActions = requiredActionsThisRound - actionsTakenThisRound

        if missingActions > 0 {
            allActionsCorrectThisRound = false
            actionsTakenThisRound = requiredActionsThisRound
            finalizeRound()
        }
    }

    // start the timer on the game
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

                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    // Advance the round
    private func proceed() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            nextRound()
        }
    }
}
