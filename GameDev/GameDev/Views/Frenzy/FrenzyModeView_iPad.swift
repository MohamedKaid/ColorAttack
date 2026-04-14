//
//  Untitled.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid

import SwiftUI
import GameKit

struct FrenzyModeView_iPad: View {
    @Binding var currentScreen: AppScreen
    let colorPool: [GameColor]

    @State private var cards: [FrenzyCard] = []
    @State private var targetColor: GameColor? = nil
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false
    @State private var showCountdown: Bool = true
    @State private var showSettings: Bool = false

    @State private var timeRemaining: Double = 4.0
    @State private var timerProgress: Double = 1.0

    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear
    @State private var showLifeLostFlash: Bool = false
    @State private var animateHearts: Bool = false

    @State private var displayLink: Timer? = nil
    @State private var timerTask: Task<Void, Never>? = nil

    @State private var bestScore: Int = 0
    @State private var arenaSize: CGSize = .zero

    private var currentLevel: FrenzyLevel { FrenzyRules.level(for: score) }
    private var levelNumber: Int { FrenzyRules.levelNumber(for: score) }

    var body: some View {
        ZStack {
            GameBackground(mode: .chaos).ignoresSafeArea()

            if showLifeLostFlash {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false).transition(.opacity)
            }

            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Side panel
                    VStack(spacing: 24) {
                        Spacer()

                        // Prompt
                        VStack(spacing: 6) {
                            Text("TAP THE COLOR")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1.5)
                            Text(targetColor?.name.uppercased() ?? "")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(targetColor?.color ?? .white)
                                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.5))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        )

                        // Timer bar
                        VStack(spacing: 6) {
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(timerProgress > 0.5 ? Color.green : timerProgress > 0.25 ? Color.yellow : Color.red)
                                        .frame(width: max(0, barGeo.size.width * timerProgress), height: 8)
                                        .animation(.linear(duration: 0.1), value: timerProgress)
                                }
                            }
                            .frame(height: 8)

                            Text("LEVEL \(levelNumber)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Lives
                        HStack(spacing: 10) {
                            ForEach(0..<max(0, lives), id: \.self) { _ in
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 22))
                                    .scaleEffect(animateHearts ? 0.75 : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                            }
                        }

                        // Score
                        VStack(spacing: 2) {
                            Text("SCORE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(score)")
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Back button
                        Button {
                            stopGame()
                            currentScreen = .modeSelection
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left").font(.subheadline.weight(.semibold))
                                Text("Home").font(.subheadline.weight(.semibold))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                        }

                        Spacer()
                    }
                    .frame(width: geo.size.width * 0.22)
                    .padding(.horizontal, 16)

                    // Arena
                    ZStack {
                        ForEach(cards) { card in
                            FrenzyCardView(gameColor: card.gameColor)
                                .frame(width: card.size, height: card.size)
                                .position(x: card.x + card.size / 2, y: card.y + card.size / 2)
                                .onTapGesture { handleTap(card: card) }
                        }

                        if !feedbackText.isEmpty {
                            let iconName = feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill"
                            HStack(spacing: 5) {
                                Image(systemName: iconName).foregroundColor(feedbackColor).font(.system(size: 14, weight: .bold))
                                Text(feedbackText).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Capsule().fill(feedbackColor.opacity(0.3)).overlay(Capsule().stroke(feedbackColor.opacity(0.5), lineWidth: 1)))
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
                            .transition(.opacity)
                            .animation(.easeOut(duration: 0.2), value: feedbackText)
                        }
                    }
                    .onAppear { arenaSize = CGSize(width: geo.size.width * 0.78, height: geo.size.height) }
                    .onChange(of: geo.size) { _, s in arenaSize = CGSize(width: s.width * 0.78, height: s.height) }
                }
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
        .onDisappear { stopGame() }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("GAME OVER").font(.system(size: 32, weight: .heavy, design: .rounded)).foregroundColor(.white)
                Text("Score: \(score)").font(.system(size: 20, weight: .semibold)).foregroundColor(.white.opacity(0.85))
                HStack(spacing: 16) {
                    Button { stopGame(); currentScreen = .modeSelection } label: {
                        Text("Home").font(.headline).frame(minWidth: 120, minHeight: 48).foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1)))
                    }
                    Button { restartGame() } label: {
                        Text("Restart").font(.headline).frame(minWidth: 120, minHeight: 48).foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [Color(hex: "FF3CAC"), Color(hex: "784BA0")], startPoint: .leading, endPoint: .trailing)))
                    }
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.85)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1)))
        }
    }

    private func startGame() {
        score = 0; lives = 3; isGameOver = false
        spawnRound(); startMoveLoop(); startRoundTimer()
        AudioPlayer.shared.playMusic("Chaos Theme")
        loadMyBestScore(leaderboardID: GameMode.frenzy.leaderboardID) { s in bestScore = s }
    }

    private func stopGame() {
        displayLink?.invalidate(); displayLink = nil
        timerTask?.cancel(); timerTask = nil
        AudioPlayer.shared.stopMusic()
    }

    private func restartGame() { stopGame(); showCountdown = true }

    private func spawnRound() {
        guard !arenaSize.isEmpty else { return }
        let level = currentLevel
        let shuffled = colorPool.shuffled().prefix(level.cardCount)
        targetColor = shuffled.randomElement()!
        let cardSize = FrenzyRules.minCardSize
        let maxX = arenaSize.width - cardSize
        let maxY = arenaSize.height - cardSize
        cards = shuffled.map { color in
            let angle = Double.random(in: 0..<(2 * .pi))
            return FrenzyCard(
                gameColor: color,
                x: CGFloat.random(in: 8...max(8, maxX - 8)),
                y: CGFloat.random(in: 8...max(8, maxY - 8)),
                vx: CGFloat(cos(angle)) * level.speed,
                vy: CGFloat(sin(angle)) * level.speed
            )
        }
        timeRemaining = level.tapTimeLimit; timerProgress = 1.0
    }

    private func startMoveLoop() {
        displayLink?.invalidate()
        displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in moveCards() }
    }

    private func moveCards() {
        guard !arenaSize.isEmpty else { return }
        let cardSize = FrenzyRules.minCardSize
        let maxX = arenaSize.width - cardSize; let maxY = arenaSize.height - cardSize
        for i in cards.indices {
            cards[i].x += cards[i].vx; cards[i].y += cards[i].vy
            if cards[i].x <= 0 || cards[i].x >= maxX { cards[i].vx *= -1; cards[i].x = max(0, min(maxX, cards[i].x)) }
            if cards[i].y <= 0 || cards[i].y >= maxY { cards[i].vy *= -1; cards[i].y = max(0, min(maxY, cards[i].y)) }
        }
    }

    private func startRoundTimer() {
        timerTask?.cancel()
        let limit = currentLevel.tapTimeLimit
        timerTask = Task {
            let interval = 0.05; var elapsed = 0.0
            while elapsed < limit {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { return }
                elapsed += interval
                await MainActor.run { timerProgress = max(0, 1.0 - (elapsed / limit)) }
            }
            await MainActor.run { handleTimeout() }
        }
    }

    private func handleTap(card: FrenzyCard) {
        guard !isGameOver else { return }
        if card.gameColor.name == targetColor?.name {
            score += FrenzyRules.pointsPerTap
            showFeedback(text: "+\(FrenzyRules.pointsPerTap)", color: .green)
            timerTask?.cancel(); spawnRound(); startRoundTimer()
            submitScoreIfBest()
        } else { loseLife() }
    }

    private func handleTimeout() {
        guard !isGameOver else { return }
        loseLife()
        if !isGameOver { spawnRound(); startRoundTimer() }
    }

    private func loseLife() {
        lives -= 1
        showFeedback(text: "−1 Life", color: .red)
        animateHearts = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { animateHearts = false }
        withAnimation(.easeIn(duration: 0.1)) { showLifeLostFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { withAnimation(.easeOut(duration: 0.2)) { showLifeLostFlash = false } }
        if lives <= 0 { isGameOver = true; stopGame(); submitScoreIfBest() }
    }

    private func showFeedback(text: String, color: Color) {
        feedbackText = text; feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text { withAnimation { feedbackText = "" } }
        }
    }

    private func submitScoreIfBest() {
        guard score > bestScore else { return }
        bestScore = score
        Task {
            try? await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [GameMode.frenzy.leaderboardID])
        }
    }
}
