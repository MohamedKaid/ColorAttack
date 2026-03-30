//
//  ChaosModeView_iPhone.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/12/26.
//

import SwiftUI

struct ChaosModeView_iPhone: View {
    @ObservedObject var engine: GameEngine
    @Binding var currentScreen: AppScreen

    // MARK: - State

    @State private var bestChaosScore = 0
    @State private var lastLives: Int = 0
    @State private var lastScore: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false
    @State private var showCountdown = true
    @State private var showSettings = false
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    // MARK: - Computed

    private var isZoomed: Bool {
        UIScreen.main.scale > UIScreen.main.nativeScale || UIScreen.main.bounds.width < 375
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let isSmall = isZoomed ? false : geo.size.width < 380

            ZStack {
                GameBackground(mode: .chaos)
                    .ignoresSafeArea()

                if showLifeLostFlash {
                    Color.red
                        .opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                mainContent(geo: geo, isSmall: isSmall)

                overlays
            }
            .safeAreaInset(edge: .top) {
                header(isSmall: isSmall)
            }
            .onChange(of: engine.lives.current) { _, _ in handleLivesChange() }
            .onChange(of: engine.score) { _, _ in handleScoreChange() }
            .onAppear { handleAppear() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: - Main Content

    private func mainContent(geo: GeometryProxy, isSmall: Bool) -> some View {
        VStack(spacing: isSmall ? 8 : 10) {
            Spacer(minLength: 6)

            ChaosInstructionView(text: engine.promptText)
                .padding(.horizontal, 12)

            feedbackToast

            tapTimerView

            splitGridContent(availableWidth: geo.size.width, availableHeight: geo.size.height)

            Spacer(minLength: 6)
        }
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Split Grid

    private func splitGridContent(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        let horizontalPadding: CGFloat = 24
        let columnSpacing: CGFloat = 12
        let cardSpacing: CGFloat = 8

        // ✅ Derive column width purely from available width — no GeometryReader needed
        let columnWidth = (availableWidth - horizontalPadding - columnSpacing) / 2
        let cardWidth = (columnWidth - cardSpacing) / 2
        let cardHeight = cardWidth * 1.15

        return HStack(alignment: .top, spacing: columnSpacing) {

            // Colors — Left
            VStack(spacing: 6) {
                sectionLabel(title: "COLORS", icon: "paintpalette.fill")
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: cardSpacing), count: 2),
                    spacing: cardSpacing
                ) {
                    ForEach(engine.gridColors) { gameColor in
                        Button {
                            engine.handleTap(action: .colorTap(gameColor))
                        } label: {
                            CardView(gameColor: gameColor)
                                .frame(height: cardHeight)
                        }
                        .buttonStyle(.plain)
                        .disabled(engine.isGameOver)
                    }
                }
            }

            // Shapes — Right
            VStack(spacing: 6) {
                sectionLabel(title: "SHAPES", icon: "square.on.circle.fill")
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: cardSpacing), count: 2),
                    spacing: cardSpacing
                ) {
                    ForEach(engine.gridShapes) { shape in
                        Button {
                            engine.handleTap(action: .shapeTap(shape))
                        } label: {
                            ShapeCardView(shape: shape)
                                .frame(height: cardHeight)
                        }
                        .buttonStyle(.plain)
                        .disabled(engine.isGameOver)
                    }
                }
            }
        }
        .padding(.horizontal, horizontalPadding / 2)
    }

    private func sectionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white.opacity(0.6))
        .font(.system(size: 11))
    }

    // MARK: - Tap Timer

    private var tapTimerView: some View {
        let isUrgent = engine.remainingTapTime < 1.0
        let timerColor: Color = isUrgent ? .red : .yellow
        let textColor: Color = isUrgent ? .red : .white
        let bgColor: Color = isUrgent ? Color.red.opacity(0.28) : Color.black.opacity(0.38)

        return HStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(timerColor)
                .font(.system(size: 13))
            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(bgColor)
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
        .scaleEffect(flashTimer ? 1.08 : 1.0)
        .onChange(of: isUrgent) { _, newValue in flashTimer = newValue }
        .animation(
            flashTimer
                ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true)
                : .default,
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
            }
        }
        .frame(height: 28)
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

            VStack(spacing: 12) {
                Text("Game Over")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)

                Text("Final Score: \(engine.score)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 12) {
                    Button("Home") {
                        engine.stop()
                        currentScreen = .modeSelection
                    }
                    .font(.headline)
                    .frame(minWidth: 100, minHeight: 44)
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button("Restart") {
                        showCountdown = true
                    }
                    .font(.headline)
                    .frame(minWidth: 100, minHeight: 44)
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
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

    private func header(isSmall: Bool) -> some View {
        HStack(spacing: 8) {
            backButton
            livesView(isSmall: isSmall)
            Spacer()
            scoreView(valueSize: isSmall ? 16 : 18)
            settingsButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
    }

    private var backButton: some View {
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
    }

    private func livesView(isSmall: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<engine.lives.current, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: isSmall ? 16 : 18, weight: .bold))
                    .scaleEffect(animateHearts ? 0.75 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
            }
        }
    }

    private func scoreView(valueSize: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("SCORE")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Text("\(engine.score)")
                .font(.system(size: valueSize, weight: .heavy))
                .foregroundColor(.white)
            Text("Best: \(bestChaosScore)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var settingsButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.black.opacity(0.25)))
        }
    }

    // MARK: - Event Handlers

    private func handleLivesChange() {
        if engine.lives.current < lastLives {
            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { animateHearts = false }

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
            bestChaosScore = score
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
}

// MARK: - Preview

#Preview("Chaos Mode") {
    ChaosModeView_iPhone(
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
        ),
        currentScreen: .constant(.chaos)
    )
}
