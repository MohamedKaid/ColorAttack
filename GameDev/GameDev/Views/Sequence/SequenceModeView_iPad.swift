//
//  SequenceModeView_iPad.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 3/30/26.
//

import SwiftUI
import GameKit

struct SequenceModeView_iPad: View {
    @Binding var currentScreen: AppScreen
    @ObservedObject var engine: GameEngine

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
    private let leaderboardID = "com.example.ColorAttack.Sequence.Placeholder"

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
                    mainContent(w: w, h: h)
                }

                overlays
            }
            .safeAreaInset(edge: .top) {
                header(w: w, h: h)
            }
            .onAppear { handleAppear() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: - Main Content

    private func mainContent(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {

            // Left panel — progress tracker + feedback
            VStack(spacing: h * 0.03) {
                Spacer()

                Text("TAP IN ORDER")
                    .font(.system(size: h * 0.02, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)

                sequenceProgressView(w: w, h: h)

                feedbackToast(h: h)

                Spacer()
            }
            .frame(width: w * 0.18)
            .padding(.leading, w * 0.02)

            // Right panel — 3 column grid fills remaining space
            gridView(w: w, h: h)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, w * 0.02)
        }
        .blur(radius: showSettings ? 8 : 0)
        .allowsHitTesting(!showSettings)
    }

    // MARK: - Sequence Progress

    private func sequenceProgressView(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: h * 0.012) {
            ForEach(0..<sequence.count, id: \.self) { i in
                HStack(spacing: w * 0.008) {
                    Circle()
                        .fill(progressColor(for: i))
                        .frame(width: h * 0.018, height: h * 0.018)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor(for: i))
                        .frame(maxWidth: .infinity)
                        .frame(height: h * 0.01)
                }
                .animation(.spring(response: 0.3), value: sequenceIndex)
            }
        }
        .padding(h * 0.018)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.35))
        )
    }

    private func progressColor(for index: Int) -> Color {
        if index < sequenceIndex { return .green }
        if index == sequenceIndex { return .white }
        return Color.white.opacity(0.25)
    }

    // MARK: - Grid (3 columns to avoid overflow)

    private func gridView(w: CGFloat, h: CGFloat) -> some View {
        let columnCount = 3
        let rowCount = 4
        let spacing: CGFloat = h * 0.028

        // Available width is everything after the left panel and paddings
        let availableW = w * 0.76
        let cardW = (availableW - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        let cardH = cardW * 0.45

        let safeGrid = Array(grid.prefix(12))

        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: columnCount),
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

    private func feedbackToast(h: CGFloat) -> some View {
        ZStack {
            if !feedbackText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(feedbackColor)
                        .font(.system(size: h * 0.024, weight: .bold))
                    Text(feedbackText)
                        .font(.system(size: h * 0.024, weight: .semibold))
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
            }
        }
        .frame(height: 36)
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
            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.largeTitle).bold().foregroundColor(.white)
                Text("Final Score: \(score)")
                    .font(.headline).foregroundColor(.white.opacity(0.9))
                Button("Home") {
                    engine.stop()
                    currentScreen = .modeSelection
                }
                .buttonStyle(.bordered).tint(.green)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
        }
    }

    // MARK: - Header

    private func header(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            Button {
                engine.stop()
                currentScreen = .modeSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: h * 0.03, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, w * 0.02)

            Text("Best: \(bestScore)")
                .font(.system(size: h * 0.03, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 8)

            Spacer()

            // Lives centre
            HStack(spacing: 10) {
                ForEach(0..<lives, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: h * 0.038, weight: .bold))
                        .scaleEffect(animateHearts ? 0.7 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            Spacer()

            // Score + Settings
            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: h * 0.016, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: h * 0.034, weight: .bold))
                    .foregroundColor(.white)
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: h * 0.028))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, 12)
            .padding(.trailing, w * 0.02)
        }
        .padding(.vertical, h * 0.015)
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Game Logic

    private func handleAppear() {
        AudioPlayer.shared.playMusic("Classic Theme")
        showCountdown = true
        didSubmitScore = false
        loadMyBestScore(leaderboardID: leaderboardID) { s in bestScore = s }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { startRound() }
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
            }
        }
    }

    private func submitScore() {
        guard !didSubmitScore else { return }
        guard GKLocalPlayer.local.isAuthenticated else { return }
        didSubmitScore = true
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score, context: 0,
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

    private func showFeedback(text: String, color: Color) {
        feedbackText = text
        feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text { withAnimation { feedbackText = "" } }
        }
    }
}

#Preview {
    SequenceModeView_iPad(
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
