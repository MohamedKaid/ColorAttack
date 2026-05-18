//
//  ChaosModeView_iPad.swift
//  Color Frenzy
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ChaosModeView_iPad: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    @State private var bestChaosScore = 0
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
        ZStack {
            GameBackground(mode: .chaos)
                .ignoresSafeArea()

            if showLifeLostFlash {
                Color.red.opacity(0.25)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // GeometryReader INSIDE the safe-area-respecting ZStack
            // so w/h reflect the actual usable canvas, not the full screen
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                mainContent(w: w, h: h)
            }

            overlays
        }
        .safeAreaInset(edge: .top) {
            GeometryReader { geo in
                header(w: geo.size.width)
                    .frame(width: geo.size.width)
            }
            .frame(height: 56)
        }
        .onChange(of: engine.round) { _, _ in
            swapSides = engine.round >= 12 ? Bool.random() : false
        }
        .onChange(of: engine.lives.current) { _, _ in handleLivesChange() }
        .onChange(of: engine.score) { _, _ in handleScoreChange() }
        .onChange(of: engine.isGameOver) { _, isOver in
            guard isOver else { return }
            NotificationManager.shared.handleGameOver(score: engine.score, mode: .chaos)
        }
        .onAppear { handleAppear() }
        .onDisappear { engine.stop() }
    }

    // MARK: - Main Content
    // Landscape layout: 38% left grid | 24% centre | 38% right grid

    private func mainContent(w: CGFloat, h: CGFloat) -> some View {

        // Grid panels
        let gridPanelW = w * 0.38
        let centrePanelW = w * 0.24
        let columnCount = 2
        let cardSpacing: CGFloat = 10
        let outerPadding: CGFloat = 14

        let cardW = (gridPanelW - outerPadding * 2 - cardSpacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)

        // Fit 3 rows inside the available height (label + 3 rows + spacing + vertical padding)
        let labelAndPadding: CGFloat = 52
        let rowCount: CGFloat = 3
        let totalRowSpacing = cardSpacing * (rowCount - 1)
        let maxCardH = (h - labelAndPadding - totalRowSpacing) / rowCount
        let cardH = min(cardW * 0.80, maxCardH)

        return HStack(spacing: 0) {
            gridPanel(
                title: swapSides ? "SHAPES" : "COLORS",
                icon: swapSides ? "square.on.circle.fill" : "paintpalette.fill",
                panelW: gridPanelW,
                cardW: cardW,
                cardH: cardH,
                outerPadding: outerPadding,
                cardSpacing: cardSpacing,
                isShapes: swapSides
            )

            centrePanel(panelW: centrePanelW, availableH: h)
                .frame(width: centrePanelW)

            gridPanel(
                title: swapSides ? "COLORS" : "SHAPES",
                icon: swapSides ? "paintpalette.fill" : "square.on.circle.fill",
                panelW: gridPanelW,
                cardW: cardW,
                cardH: cardH,
                outerPadding: outerPadding,
                cardSpacing: cardSpacing,
                isShapes: !swapSides
            )
        }
        .animation(.easeInOut(duration: 0.25), value: swapSides)
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Grid Panel

    private func gridPanel(
        title: String,
        icon: String,
        panelW: CGFloat,
        cardW: CGFloat,
        cardH: CGFloat,
        outerPadding: CGFloat,
        cardSpacing: CGFloat,
        isShapes: Bool
    ) -> some View {
        let columns = Array(repeating: GridItem(.fixed(cardW), spacing: cardSpacing), count: 2)

        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.65))
            .font(.system(size: 13))

            if isShapes {
                LazyVGrid(columns: columns, spacing: cardSpacing) {
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
            } else {
                LazyVGrid(columns: columns, spacing: cardSpacing) {
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
        }
        .frame(width: panelW)
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }

    // MARK: - Centre Panel

    private func centrePanel(panelW: CGFloat, availableH: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()

            ChaosInstructionView(text: engine.promptText)

            feedbackToast

            tapTimerView

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Tap Timer

    private var tapTimerView: some View {
        let isUrgent = engine.remainingTapTime < 1.0

        return HStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(isUrgent ? .red : .yellow)
                .font(.system(size: 16))
            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isUrgent ? .red : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isUrgent ? Color.red.opacity(0.3) : Color.black.opacity(0.4))
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .scaleEffect(flashTimer ? 1.08 : 1.0)
        .onChange(of: isUrgent) { _, newValue in flashTimer = newValue }
        .animation(
            flashTimer ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
            value: flashTimer
        )
    }

    // MARK: - Feedback Toast

    private var feedbackToast: some View {
        ZStack {
            if !feedbackText.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(feedbackColor)
                        .font(.system(size: 14, weight: .bold))
                    Text(feedbackText)
                        .font(.system(size: 14, weight: .semibold))
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
        .frame(height: 34)
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
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Game Over")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.white)

                Text("Final Score: \(engine.score)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                Text("Best: \(bestChaosScore)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))

                HStack(spacing: 14) {
                    Button("Home") {
                        engine.stop()
                        currentScreen = .modeSelection
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 110, minHeight: 44)
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button("Play Again") {
                        showCountdown = true
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 110, minHeight: 44)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Header
    // Fixed pt sizes — header should look the same regardless of screen size

    private func header(w: CGFloat) -> some View {
        HStack(spacing: 8) {

            Button {
                engine.stop()
                currentScreen = .modeSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
            .padding(.leading, w * 0.015)

            VStack(alignment: .leading, spacing: 1) {
                Text("Best")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(bestChaosScore)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Lives centred in header
            HStack(spacing: 8) {
                ForEach(0..<engine.lives.current, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20, weight: .bold))
                        .scaleEffect(animateHearts ? 0.72 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(engine.score)")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
            .padding(.trailing, w * 0.015)
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
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
        AudioPlayer.shared.playMusic("Chaos Theme")
        lastLives = engine.lives.current
        lastScore = engine.score
        showCountdown = true
        loadMyBestScore(leaderboardID: "com.example.ColorAttack.Chaos") { score in
            bestChaosScore = score
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

// MARK: - Preview

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
