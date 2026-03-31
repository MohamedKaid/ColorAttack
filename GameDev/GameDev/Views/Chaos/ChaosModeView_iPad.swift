//
//  ChaosModeView_iPad.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ChaosModeView_iPad: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    @State private var bestClassicScore = 0
    @State private var swapSides = false
    @State private var lastLives: Int = 0
    @State private var lastScore: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false
    @State private var showCountdown = true
    @State private var showSettings = false
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                GameBackground(mode: .chaos)
                    .ignoresSafeArea()

                if showLifeLostFlash {
                    Color.red.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                mainContent(w: w, h: h)

                overlays
            }
            .safeAreaInset(edge: .top) {
                header(w: w, h: h)
            }
            .onChange(of: engine.round) { _, _ in
                swapSides = engine.round >= 12 ? Bool.random() : false
            }
            .onChange(of: engine.lives.current) { _, _ in handleLivesChange() }
            .onChange(of: engine.score) { _, _ in handleScoreChange() }
            .onAppear { handleAppear() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: - Main Content

    private func mainContent(w: CGFloat, h: CGFloat) -> some View {
        // Landscape: centre panel for prompt/timer, flanked by two grids
        HStack(spacing: w * 0.02) {

            // Left grid — colors or shapes depending on swapSides
            if swapSides {
                shapesGrid(w: w, h: h)
            } else {
                colorsGrid(w: w, h: h)
            }

            // Centre panel
            VStack(spacing: h * 0.025) {
                Spacer()
                ChaosInstructionView(text: engine.promptText)
                feedbackToast(w: w)
                tapTimerView(w: w, h: h)
                Spacer()
            }
            .frame(width: w * 0.3)

            // Right grid
            if swapSides {
                colorsGrid(w: w, h: h)
            } else {
                shapesGrid(w: w, h: h)
            }
        }
        .padding(.horizontal, w * 0.02)
        .animation(.easeInOut(duration: 0.25), value: swapSides)
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Color Grid

    private func colorsGrid(w: CGFloat, h: CGFloat) -> some View {
        let columnCount = 3
        let spacing: CGFloat = h * 0.022
        let panelW = w * 0.32
        let cardW = (panelW - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        let cardH = cardW * 0.75

        return VStack(spacing: h * 0.015) {
            Text("COLORS")
                .font(.system(size: h * 0.022, weight: .bold))
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: columnCount),
                spacing: spacing
            ) {
                ForEach(engine.gridColors) { gameColor in
                    Button {
                        engine.handleTap(action: .colorTap(gameColor))
                    } label: {
                        CardView(gameColor: gameColor)
                            .frame(width: cardW, height: cardH)
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.isGameOver)
                }
            }
        }
        .frame(width: panelW)
    }

    // MARK: - Shape Grid

    private func shapesGrid(w: CGFloat, h: CGFloat) -> some View {
        let columnCount = 2
        let spacing: CGFloat = h * 0.022
        let panelW = w * 0.32
        let cardW = (panelW - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        let cardH = cardW * 0.85

        return VStack(spacing: h * 0.015) {
            Text("SHAPES")
                .font(.system(size: h * 0.022, weight: .bold))
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: columnCount),
                spacing: spacing
            ) {
                ForEach(engine.gridShapes) { shape in
                    Button {
                        engine.handleTap(action: .shapeTap(shape))
                    } label: {
                        ShapeCardView(shape: shape)
                            .frame(width: cardW, height: cardH)
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.isGameOver)
                }
            }
        }
        .frame(width: panelW)
    }

    // MARK: - Tap Timer

    private func tapTimerView(w: CGFloat, h: CGFloat) -> some View {
        let isUrgent = engine.remainingTapTime < 1.0

        return HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(isUrgent ? .red : .yellow)
                .font(.system(size: h * 0.03))
            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: h * 0.035, weight: .bold))
                .foregroundColor(isUrgent ? .red : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isUrgent ? Color.red.opacity(0.3) : Color.black.opacity(0.4))
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .scaleEffect(flashTimer ? 1.1 : 1.0)
        .onChange(of: isUrgent) { _, newValue in flashTimer = newValue }
        .animation(
            flashTimer ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
            value: flashTimer
        )
    }

    // MARK: - Feedback Toast

    private func feedbackToast(w: CGFloat) -> some View {
        ZStack {
            if !feedbackText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(feedbackColor)
                        .font(.system(size: w * 0.018, weight: .bold))
                    Text(feedbackText)
                        .font(.system(size: w * 0.018, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
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
            if engine.isGameOver { gameOverOverlay }
            if showCountdown {
                CountdownView {
                    showCountdown = false
                    engine.start()
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
                Text("Final Score: \(engine.score)")
                    .font(.headline).foregroundColor(.white.opacity(0.9))
                Button("Home") {
                    engine.stop()
                    currentScreen = .modeSelection
                }
                .buttonStyle(.bordered).tint(.blue)
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
        ZStack {
            HStack {
                Button {
                    engine.stop()
                    currentScreen = .modeSelection
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: h * 0.03, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }

                Text("Best: \(bestClassicScore)")
                    .font(.system(size: h * 0.032, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(0..<engine.lives.current, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: h * 0.04, weight: .bold))
                        .scaleEffect(animateHearts ? 0.7 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("SCORE")
                        .font(.system(size: h * 0.018, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(engine.score)")
                        .font(.system(size: h * 0.038, weight: .bold))
                        .foregroundColor(.white)
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: h * 0.03))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.leading, 12)
                .padding(.trailing, 20)
            }
        }
        .padding(.horizontal, w * 0.025)
        .padding(.vertical, h * 0.015)
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Event Handlers

    private func handleLivesChange() {
        if engine.lives.current < lastLives {
            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { animateHearts = false }
            withAnimation(.easeIn(duration: 0.1)) { showLifeLostFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) { showLifeLostFlash = false }
            }
            showFeedback(text: "−1 Life", color: .red)
        }
        lastLives = engine.lives.current
    }

    private func handleScoreChange() {
        if engine.score > lastScore {
            showFeedback(text: "+\(engine.score - lastScore)", color: .green)
        } else if engine.score < lastScore {
            showFeedback(text: "\(engine.score - lastScore)", color: .red)
        }
        lastScore = engine.score
    }

    private func handleAppear() {
        lastLives = engine.lives.current
        lastScore = engine.score
        showCountdown = true
        loadMyBestScore(leaderboardID: "com.example.ColorAttack.Chaos") { score in
            bestClassicScore = score
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

#Preview("Chaos Mode iPad") {
    ChaosModeView_iPad(
        currentScreen: .constant(.chaos),
        engine: GameEngine(
            lives: Lives(max: 5),
            colorPool: colorPool,
            config: ModeConfig(
                cardsPerGrid: 6,
                tapTimeLimit: 2.5,
                usesLives: true,
                totalGameTimeLimit: nil,
                leaderboardID: "com.example.ColorAttack.Chaos"
            ),
            rules: ChaosRules()
        )
    )
}
