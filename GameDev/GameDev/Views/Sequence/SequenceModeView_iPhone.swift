//
//  SequenceModeView_iPhone.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 3/30/26.
//

import SwiftUI
import GameKit

struct SequenceModeView_iPhone: View {
    @Binding var currentScreen: AppScreen
    @ObservedObject var engine: GameEngine

    // MARK: - State

    @State private var sequenceRules = SequenceRules()
    @State private var grid: [SequenceGridItem] = []
    @State private var sequence: [SequenceItem] = []
    @State private var sequenceIndex: Int = 0

    @State private var score: Int = 0
    @State private var lives: Int = 5
    @State private var round: Int = 0

    @State private var showDisplayPhase: Bool = false
    @State private var showRecallPhase: Bool = false
    @State private var showCountdown: Bool = true
    @State private var showSettings: Bool = false
    @State private var isGameOver: Bool = false

    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear
    @State private var showLifeLostFlash: Bool = false
    @State private var animateHearts: Bool = false

    @State private var bestScore: Int = 0
    @State private var didSubmitScore: Bool = false

    // TODO: Replace with real Game Center leaderboard ID once created
    private let leaderboardID = "com.example.ColorAttack.Sequence"

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                GameBackground(mode: .sequence)
                    .ignoresSafeArea()

                if showLifeLostFlash {
                    Color.red.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                if showRecallPhase {
                    recallContent(w: w, h: h)
                }

                overlays
            }
            .safeAreaInset(edge: .top) {
                header(w: w)
            }
            .onAppear { handleAppear() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: - Recall Content

    private func recallContent(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: h * 0.012) {
            Spacer(minLength: h * 0.01)
            sequenceProgressView(w: w)
            feedbackToast(w: w)
            gridView(w: w, h: h)
            Spacer(minLength: h * 0.01)
        }
        .blur(radius: showSettings ? 8 : 0)
        .allowsHitTesting(!showSettings)
    }

    // MARK: - Sequence Progress Bar

    private func sequenceProgressView(w: CGFloat) -> some View {
        VStack(spacing: w * 0.02) {
            Text("TAP IN ORDER")
                .font(.system(size: w * 0.032, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(3)

            HStack(spacing: w * 0.015) {
                ForEach(0..<sequence.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: w * 0.01)
                        .fill(progressColor(for: i))
                        .frame(
                            width: i == sequenceIndex ? w * 0.062 : w * 0.042,
                            height: w * 0.02
                        )
                        .animation(.spring(response: 0.3), value: sequenceIndex)
                }
            }
            .padding(.horizontal, w * 0.04)
        }
        .padding(.vertical, w * 0.025)
        .padding(.horizontal, w * 0.04)
        .background(
            RoundedRectangle(cornerRadius: w * 0.03)
                .fill(Color.black.opacity(0.35))
        )
        .padding(.horizontal, w * 0.04)
    }

    private func progressColor(for index: Int) -> Color {
        if index < sequenceIndex { return .green }
        if index == sequenceIndex { return .white }
        return Color.white.opacity(0.25)
    }

    // MARK: - Grid

    private func gridView(w: CGFloat, h: CGFloat) -> some View {
        let columns = 3
        let horizontalPadding = w * 0.04
        let spacing = w * 0.025
        let cardW = (w - horizontalPadding * 2 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let cardH = cardW * 0.72
        let safeGrid = Array(grid.prefix(12))

        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(safeGrid) { item in
                Button {
                    handleTap(item)
                } label: {
                    gridItemView(item)
                        .frame(width: cardW, height: cardH)
                }
                .buttonStyle(.plain)
                .disabled(isGameOver)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    @ViewBuilder
    private func gridItemView(_ item: SequenceGridItem) -> some View {
        switch item {
        case .color(let gameColor):
            CardView(gameColor: gameColor)
        case .shape(let gameShape):
            ShapeCardView(shape: gameShape)
        }
    }

    // MARK: - Feedback Toast

    private func feedbackToast(w: CGFloat) -> some View {
        ZStack {
            if !feedbackText.isEmpty {
                HStack(spacing: w * 0.012) {
                    Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(feedbackColor)
                        .font(.system(size: w * 0.034, weight: .bold))
                    Text(feedbackText)
                        .font(.system(size: w * 0.034, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, w * 0.032)
                .padding(.vertical, w * 0.016)
                .background(
                    Capsule()
                        .fill(feedbackColor.opacity(0.3))
                        .overlay(Capsule().stroke(feedbackColor.opacity(0.5), lineWidth: 1))
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(height: w * 0.072)
        .animation(.easeOut(duration: 0.2), value: feedbackText)
    }

    // MARK: - Overlays

    private var overlays: some View {
        ZStack {
            if showDisplayPhase {
                SequenceDisplayView(sequence: sequence) {
                    withAnimation {
                        showDisplayPhase = false
                        showRecallPhase = true
                    }
                }
                .transition(.opacity)
            }

            if isGameOver { gameOverOverlay }

            if showCountdown {
                CountdownView {
                    showCountdown = false
                    startRound()
                }
            }

            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Game Over")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)

                Text("Final Score: \(score)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                Button("Home") {
                    engine.stop()
                    currentScreen = .modeSelection
                }
                .font(.headline)
                .frame(minWidth: 120, minHeight: 44)
                .buttonStyle(.bordered)
                .tint(.green)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Header

    private func header(w: CGFloat) -> some View {
        HStack(spacing: w * 0.02) {
            backButton(w: w)

            VStack(alignment: .leading, spacing: 1) {
                Text("Best")
                    .font(.system(size: w * 0.026, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(bestScore)")
                    .font(.system(size: w * 0.046, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: w * 0.015) {
                ForEach(0..<lives, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: w * 0.046, weight: .bold))
                        .scaleEffect(animateHearts ? 0.75 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: w * 0.026, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: w * 0.046, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            settingsButton(w: w)
        }
        .padding(.horizontal, w * 0.032)
        .padding(.vertical, w * 0.026)
        .background(Color.black.opacity(0.45))
    }

    private func backButton(w: CGFloat) -> some View {
        Button {
            engine.stop()
            currentScreen = .modeSelection
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: w * 0.042, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: w * 0.092, height: w * 0.092)
                .background(Circle().fill(Color.black.opacity(0.25)))
        }
    }

    private func settingsButton(w: CGFloat) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: w * 0.042, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: w * 0.092, height: w * 0.092)
                .background(Circle().fill(Color.black.opacity(0.25)))
        }
    }

    // MARK: - Game Logic

    private func handleAppear() {
        AudioPlayer.shared.playMusic("Classic Theme")
        showCountdown = true
        didSubmitScore = false
        loadMyBestScore(leaderboardID: leaderboardID) { s in
            bestScore = s
        }
    }

    private func startRound() {
        round += 1
        let result = sequenceRules.buildSequenceRound(pool: colorPool, round: round)
        grid = result.grid
        sequence = result.sequence
        sequenceIndex = 0
        showRecallPhase = false
        withAnimation { showDisplayPhase = true }
    }

    private func handleTap(_ item: SequenceGridItem) {
        let correct = sequenceRules.checkTap(item)
        sequenceIndex = sequenceRules.sequenceIndex

        if correct {
            score += 10
            showFeedback(text: "+10", color: .green)

            if sequenceRules.isSequenceComplete {
                let bonus = sequenceRules.hadMistakeThisRound ? 0 : 15
                if bonus > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        score += bonus
                        showFeedback(text: "+\(bonus) BONUS!", color: .yellow)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startRound()
                }
            }
        } else {
            lives -= 1
            showFeedback(text: "−1 Life", color: .red)

            withAnimation(.easeIn(duration: 0.1)) { showLifeLostFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) { showLifeLostFlash = false }
            }

            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { animateHearts = false }

            if lives <= 0 {
                isGameOver = true
                engine.stop()
                submitScore()
                NotificationManager.shared.handleGameOver(score: score, mode: .sequence)
            }
        }
    }

    // MARK: - Score Submission

    private func submitScore() {
        guard !didSubmitScore else { return }

        guard GKLocalPlayer.local.isAuthenticated else {
            print("Game Center not authenticated — score not submitted.")
            return
        }

        didSubmitScore = true
        print("Submitting Sequence score \(score) to \(leaderboardID)")

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("Sequence score submitted:", score)
            } catch {
                print("Sequence score submit failed:", error.localizedDescription)
                didSubmitScore = false
            }
        }
    }

    // MARK: - Helpers

    private func showFeedback(text: String, color: Color) {
        feedbackText = text
        feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text {
                withAnimation { feedbackText = "" }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SequenceModeView_iPhone(
        currentScreen: .constant(.sequence),
        engine: GameEngine(
            lives: Lives(max: 5),
            colorPool: colorPool,
            config: ModeConfig(
                cardsPerGrid: 12,
                tapTimeLimit: 999,
                usesLives: true,
                totalGameTimeLimit: nil,
                leaderboardID: "com.example.ColorAttack.Sequence.Placeholder"
            ),
            rules: nil
        )
    )
}
