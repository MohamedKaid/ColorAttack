//
//  FrenzyModeView_iPhone.swift
//  GameDev
//

import SwiftUI
import GameKit

// Represents a single moving card in the frenzy arena
struct FrenzyCard: Identifiable {
    let id = UUID()
    let gameColor: GameColor
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    let size: CGFloat = FrenzyRules.minCardSize
}

struct FrenzyModeView_iPhone: View {
    @Binding var currentScreen: AppScreen
    let colorPool: [GameColor]

    // Game state
    @State private var cards: [FrenzyCard] = []
    @State private var targetColor: GameColor? = nil
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false
    @State private var showCountdown: Bool = true
    @State private var showSettings: Bool = false

    // Timer state
    @State private var timeRemaining: Double = 4.0
    @State private var timerProgress: Double = 1.0

    // Feedback
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear
    @State private var showLifeLostFlash: Bool = false
    @State private var animateHearts: Bool = false

    // Animation
    @State private var displayLink: Timer? = nil
    @State private var timerTask: Task<Void, Never>? = nil

    // Best score
    @State private var bestScore: Int = 0

    // Arena size captured from GeometryReader
    @State private var arenaSize: CGSize = .zero

    private var currentLevel: FrenzyLevel {
        FrenzyRules.level(for: score)
    }

    private var levelNumber: Int {
        FrenzyRules.levelNumber(for: score)
    }

    // Detect Display Zoom (matches your existing ClassicModeView_iPhone pattern)
    private var isZoomed: Bool {
        UIScreen.main.scale > UIScreen.main.nativeScale || UIScreen.main.bounds.width < 375
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let isSmall = isZoomed ? false : w < 380

            ZStack {
                GameBackground(mode: .chaos)
                    .ignoresSafeArea()

                if showLifeLostFlash {
                    Color.red.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                VStack(spacing: 0) {
                    // Arena
                    GeometryReader { arenaGeo in
                        ZStack {
                            ForEach(cards) { card in
                                FrenzyCardView(gameColor: card.gameColor)
                                    .frame(width: card.size, height: card.size)
                                    .position(x: card.x + card.size / 2, y: card.y + card.size / 2)
                                    .onTapGesture {
                                        handleTap(card: card)
                                    }
                            }

                            if !feedbackText.isEmpty {
                                feedbackToast
                                    .position(x: arenaGeo.size.width / 2, y: arenaGeo.size.height / 2)
                            }
                        }
                        .onAppear { arenaSize = arenaGeo.size }
                        .onChange(of: arenaGeo.size) { _, newSize in arenaSize = newSize }
                    }

                    // Timer bar + prompt
                    timerBarView(isSmall: isSmall)
                        .padding(.horizontal, isSmall ? 12 : 16)
                        .padding(.bottom, isSmall ? 6 : 8)
                }
                .blur(radius: showCountdown || showSettings ? 8 : 0)
                .allowsHitTesting(!showCountdown && !showSettings)

                if isGameOver { gameOverOverlay }

                if showCountdown && !isGameOver {
                    CountdownView {
                        showCountdown = false
                        startGame()
                    }
                }

                if showSettings {
                    SettingsPopupView(isPresented: $showSettings)
                        .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .top) {
                header(isSmall: isSmall, w: w)
            }
            .onDisappear { stopGame() }
        }
    }

    // MARK: - Header

    private func header(isSmall: Bool, w: CGFloat) -> some View {
        let iconSize: CGFloat  = isSmall ? 14 : 16
        let valueSize: CGFloat = isSmall ? 15 : 18
        let labelSize: CGFloat = isSmall ? 9  : 10
        let buttonSize: CGFloat = isSmall ? 32 : 36
        let heartSize: CGFloat = isSmall ? 15 : 18

        return HStack(spacing: isSmall ? 6 : 8) {
            // Back button
            Button {
                stopGame()
                currentScreen = .modeSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }

            // Best score
            VStack(alignment: .leading, spacing: 1) {
                Text("Best")
                    .font(.system(size: labelSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(bestScore)")
                    .font(.system(size: valueSize, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Lives
            HStack(spacing: isSmall ? 4 : 6) {
                ForEach(0..<max(0, lives), id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: heartSize, weight: .bold))
                        .scaleEffect(animateHearts ? 0.75 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: labelSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: valueSize, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // Settings button
            Button {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
        }
        .padding(.horizontal, isSmall ? 10 : 12)
        .padding(.vertical, isSmall ? 8 : 10)
        .background(Color.black.opacity(0.45))
    }

    // MARK: - Prompt

    private func promptView(isSmall: Bool) -> some View {
        let labelSize: CGFloat  = isSmall ? 9  : 10
        let promptSize: CGFloat = isSmall ? 20 : 26

        return VStack(spacing: 2) {
            Text("TAP THE COLOR")
                .font(.system(size: labelSize, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.5)
            Text(targetColor?.name.uppercased() ?? "")
                .font(.system(size: promptSize, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.vertical, isSmall ? 8 : 10)
        .padding(.horizontal, isSmall ? 14 : 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Timer Bar

    private func timerBarView(isSmall: Bool) -> some View {
        let levelSize: CGFloat = isSmall ? 9 : 10

        return VStack(spacing: isSmall ? 6 : 8) {
            promptView(isSmall: isSmall)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerBarColor)
                        .frame(width: max(0, geo.size.width * timerProgress), height: 6)
                        .animation(.linear(duration: 0.1), value: timerProgress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("LEVEL \(levelNumber)")
                    .font(.system(size: levelSize, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                Spacer()
            }
        }
    }

    private var timerBarColor: Color {
        if timerProgress > 0.5 { return .green }
        if timerProgress > 0.25 { return .yellow }
        return .red
    }

    // MARK: - Feedback Toast

    private var feedbackToast: some View {
        let iconName = feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill"

        return HStack(spacing: 5) {
            Image(systemName: iconName)
                .foregroundColor(feedbackColor)
                .font(.system(size: 13, weight: .bold))
            Text(feedbackText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(feedbackColor.opacity(0.3))
                .overlay(Capsule().stroke(feedbackColor.opacity(0.5), lineWidth: 1))
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.easeOut(duration: 0.2), value: feedbackText)
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("GAME OVER")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Score: \(score)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                HStack(spacing: 12) {
                    Button {
                        stopGame()
                        currentScreen = .modeSelection
                    } label: {
                        Text("Home")
                            .font(.headline)
                            .frame(minWidth: 110, minHeight: 44)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            )
                    }

            // ************* Restart button logic is not working save this here till we get it working **********
//                    Button {
//                        restartGame()
//                    } label: {
//                        Text("Restart")
//                            .font(.headline)
//                            .frame(minWidth: 110, minHeight: 44)
//                            .foregroundColor(.white)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(
//                                        LinearGradient(
//                                            colors: [Color(hex: "FF3CAC"), Color(hex: "784BA0")],
//                                            startPoint: .leading,
//                                            endPoint: .trailing
//                                        )
//                                    )
//                            )
//                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Game Logic

    private func startGame() {
        score = 0
        lives = 3
        isGameOver = false
        spawnRound()
        startMoveLoop()
        startRoundTimer()
        AudioPlayer.shared.playMusic("Chaos Theme")
        loadMyBestScore(leaderboardID: GameMode.frenzy.leaderboardID) { s in
            bestScore = s
        }
    }

    private func stopGame() {
        displayLink?.invalidate()
        displayLink = nil
        timerTask?.cancel()
        timerTask = nil
        AudioPlayer.shared.stopMusic()
    }

    private func restartGame() {
        stopGame()
        showCountdown = true
    }

    private func spawnRound() {
        guard arenaSize != .zero else { return }

        let level = currentLevel
        let count = level.cardCount
        let shuffled = colorPool.shuffled().prefix(count)
        let target = shuffled.randomElement()!
        targetColor = target

        let cardSize = FrenzyRules.minCardSize
        let maxX = arenaSize.width - cardSize
        let maxY = arenaSize.height - cardSize

        cards = shuffled.map { color in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = level.speed
            return FrenzyCard(
                gameColor: color,
                x: CGFloat.random(in: 8...max(8, maxX - 8)),
                y: CGFloat.random(in: 8...max(8, maxY - 8)),
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed
            )
        }

        timeRemaining = level.tapTimeLimit
        timerProgress = 1.0
    }

    private func startMoveLoop() {
        displayLink?.invalidate()
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            moveCards()
        }
    }

    private func moveCards() {
        guard !arenaSize.isEmpty else { return }
        let cardSize = FrenzyRules.minCardSize
        let maxX = arenaSize.width - cardSize
        let maxY = arenaSize.height - cardSize

        for i in cards.indices {
            cards[i].x += cards[i].vx
            cards[i].y += cards[i].vy

            if cards[i].x <= 0 || cards[i].x >= maxX {
                cards[i].vx *= -1
                cards[i].x = max(0, min(maxX, cards[i].x))
            }
            if cards[i].y <= 0 || cards[i].y >= maxY {
                cards[i].vy *= -1
                cards[i].y = max(0, min(maxY, cards[i].y))
            }
        }
    }

    private func startRoundTimer() {
        timerTask?.cancel()
        let limit = currentLevel.tapTimeLimit
        timerTask = Task {
            let interval = 0.05
            var elapsed = 0.0
            while elapsed < limit {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { return }
                elapsed += interval
                await MainActor.run {
                    timerProgress = max(0, 1.0 - (elapsed / limit))
                }
            }
            await MainActor.run {
                handleTimeout()
            }
        }
    }

    private func handleTap(card: FrenzyCard) {
        guard !isGameOver else { return }

        if card.gameColor.name == targetColor?.name {
            // Correct tap
            score += FrenzyRules.pointsPerTap
            showFeedback(text: "+\(FrenzyRules.pointsPerTap)", color: .green)
            timerTask?.cancel()
            spawnRound()
            startRoundTimer()
            submitScoreIfBest()
        } else {
            // Wrong tap
            loseLife()
        }
    }

    private func handleTimeout() {
        guard !isGameOver else { return }
        loseLife()
        if !isGameOver {
            spawnRound()
            startRoundTimer()
        }
    }

    private func loseLife() {
        lives -= 1
        showFeedback(text: "−1 Life", color: .red)

        animateHearts = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            animateHearts = false
        }

        withAnimation(.easeIn(duration: 0.1)) { showLifeLostFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) { showLifeLostFlash = false }
        }

        if lives <= 0 {
            isGameOver = true
            stopGame()
            submitScoreIfBest()
            NotificationManager.shared.handleGameOver(score: score, mode: .frenzy) // ← add here
        }
    }

    private func showFeedback(text: String, color: Color) {
        feedbackText = text
        feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text {
                withAnimation { feedbackText = "" }
            }
        }
    }

    private func submitScoreIfBest() {
        guard score > bestScore else { return }
        bestScore = score
        Task {
            try? await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [GameMode.frenzy.leaderboardID]
            )
        }
    }
}

extension CGSize {
    var isEmpty: Bool { width == 0 || height == 0 }
}
