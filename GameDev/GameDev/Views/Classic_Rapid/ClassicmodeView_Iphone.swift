//
//  ClassicModeView_iPhone.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/12/26.
//

import SwiftUI

struct ClassicModeView_iPhone: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    @State private var bestClassicScore = 0
    @State private var lastLives: Int = 0
    @State private var lastScore: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false
    @State private var showCountdown = true
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var leaderboardDetent: PresentationDetent = .medium

    // Feedback states
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    private var isRapidMode: Bool { engine.config.totalGameTimeLimit != nil }

    private var backgroundMode: GameBackground.GameMode {
        isRapidMode ? .rapid : .classic
    }

    // Detect Display Zoom
    private var isZoomed: Bool {
        UIScreen.main.scale > UIScreen.main.nativeScale || UIScreen.main.bounds.width < 375
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // ✅ Force standard layout when zoomed
            let isSmall = isZoomed ? false : width < 380

            ZStack {
                GameBackground(mode: backgroundMode)
                    .ignoresSafeArea()

                if showLifeLostFlash {
                    Color.red
                        .opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                mainContent(isSmall: isSmall, availableHeight: geo.size.height)

                overlays
            }
            .sheet(isPresented: $showLeaderboard) {
                CustomLeaderboardView(initialMode: isRapidMode ? .rapid : .classic)
                    .presentationDetents([.medium, .large], selection: $leaderboardDetent)
                    .presentationDragIndicator(.visible)
            }
            .safeAreaInset(edge: .top) {
                header(isSmall: isSmall)
            }
            .onChange(of: engine.lives.current) { _, _ in
                handleLivesChange()
            }
            .onChange(of: engine.score) { _, _ in
                handleScoreChange()
            }
            .onChange(of: engine.isGameOver) { _, isOver in
                guard isOver else { return }
                NotificationManager.shared.handleGameOver(
                    score: engine.score,
                    mode: isRapidMode ? .rapid : .classic
                )
            }
            .onAppear {
                handleAppear()
            }
            .onDisappear {
                engine.stop()
            }
        }
    }

    // MARK: - Main Content

    private func mainContent(isSmall: Bool, availableHeight: CGFloat) -> some View {
        VStack(spacing: isSmall ? 10 : 12) {
            Spacer(minLength: 8)

            promptView(isSmall: isSmall)

            feedbackToast

            if !isRapidMode {
                tapTimerView
            }

            gridView(isSmall: isSmall, availableHeight: availableHeight)

            Spacer(minLength: 8)
        }
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Prompt

    private func promptView(isSmall: Bool) -> some View {
        let isStroop = engine.currentPrompt.displayColor != nil
        let stroopColor = engine.currentPrompt.displayColor?.color ?? .white
        let isDark = (engine.currentPrompt.displayColor?.color.luminance ?? 1.0) < 0.3
        let fontSize: CGFloat = isSmall ? 20 : 24
        let textColor: Color = isStroop ? stroopColor : .white

        return Text(engine.promptText.uppercased())
            .font(.system(size: fontSize, weight: .heavy))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(promptBackground(isDark: isDark))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }

    private func promptBackground(isDark: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.45))
            .overlay(promptBorder)
    }

    private var promptBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                engine.switchOn
                ? Color.red.opacity(0.6)
                : Color.white.opacity(0.18),
                lineWidth: 2
            )
    }

    // MARK: - Feedback Toast

    private var feedbackToast: some View {
        ZStack {
            if !feedbackText.isEmpty {
                feedbackContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(height: 28)
        .animation(.easeOut(duration: 0.2), value: feedbackText)
    }

    private var feedbackContent: some View {
        let iconName = feedbackColor == .green
            ? "checkmark.circle.fill"
            : "xmark.circle.fill"

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
        .background(feedbackBackground)
    }

    private var feedbackBackground: some View {
        Capsule()
            .fill(feedbackColor.opacity(0.3))
            .overlay(
                Capsule()
                    .stroke(feedbackColor.opacity(0.5), lineWidth: 1)
            )
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
                .font(.system(size: 14))

            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(tapTimerBackground(bgColor: bgColor))
        .scaleEffect(flashTimer ? 1.08 : 1.0)
        .onChange(of: isUrgent) { _, newValue in
            flashTimer = newValue
        }
        .animation(
            flashTimer
            ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true)
            : .default,
            value: flashTimer
        )
    }

    private func tapTimerBackground(bgColor: Color) -> some View {
        Capsule()
            .fill(bgColor)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    // MARK: - Grid

    private func gridView(isSmall: Bool, availableHeight: CGFloat) -> some View {
        let columnCount = isSmall ? 2 : 3
        let spacing: CGFloat = isSmall ? 10 : 16  // ✅ More spacing
        let padding: CGFloat = isSmall ? 20 : 24
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columnCount
        )
        let isNine = engine.gridColors.count == 9
        let rowCount = max(1, CGFloat(ceil(Double(engine.gridColors.count) / Double(columnCount))))

        let reservedHeight: CGFloat = isRapidMode ? 160 : 180
        let gridAvailableHeight = max(1, availableHeight - reservedHeight)

        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = max(1, (screenWidth - padding - (CGFloat(columnCount - 1) * spacing)) / CGFloat(columnCount))
        let heightFromRatio = cardWidth * 0.65  // ✅ Taller cards
        let maxCardHeight = max(1, (gridAvailableHeight - (spacing * (rowCount - 1)) - padding) / rowCount)
        let cardHeight = min(heightFromRatio, maxCardHeight)

        return LazyVGrid(columns: columns, spacing: isNine ? spacing : spacing) {
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
        .padding(isSmall ? 10 : 12)
    }

    // MARK: - Overlays

    private var overlays: some View {
        ZStack {
            if engine.isGameOver {
                gameOverOverlay
            }

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
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            gameOverContent
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 12) {
            Text("Game Over")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.white)

            Text("Final Score: \(engine.score)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Button("Home") {
                engine.stop()
                currentScreen = .modeSelection
            }
            .font(.headline)
            .frame(minWidth: 120, minHeight: 44)
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding(24)
        .background(gameOverBackground)
        .padding(.horizontal, 16)
    }

    private var gameOverBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.black.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    // MARK: - Header

    private func header(isSmall: Bool) -> some View {
        let valueSize: CGFloat = isSmall ? 16 : 18

        return HStack(spacing: 8) {
            backButton

            bestScoreView(valueSize: valueSize)

            Spacer()

            centerStatus(isSmall: isSmall)

            Spacer()

            scoreView(valueSize: valueSize)

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

    private func bestScoreView(valueSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Best")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Text("\(bestClassicScore)")
                .font(.system(size: valueSize, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
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
                .lineLimit(1)
        }
    }

    private var settingsButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                showSettings = true
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.black.opacity(0.25)))
        }
    }

    // MARK: - Center Status

    @ViewBuilder
    private func centerStatus(isSmall: Bool) -> some View {
        let valueSize: CGFloat = isSmall ? 16 : 18

        if isRapidMode {
            rapidTimer(valueSize: valueSize)
        } else {
            livesView(isSmall: isSmall)
        }
    }

    private func rapidTimer(valueSize: CGFloat) -> some View {
        let remaining = engine.remainingGameTime ?? engine.config.totalGameTimeLimit ?? 0
        let isUrgent = remaining <= 5
        let clockColor: Color = isUrgent ? .red : .yellow

        return HStack(spacing: 5) {
            Image(systemName: "clock.fill")
                .foregroundColor(clockColor)
                .font(.system(size: 14))

            Text(formatTime(remaining))
                .font(.system(size: valueSize, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(flashTimer ? 1.08 : 1.0)
        .onChange(of: isUrgent) { _, newValue in
            flashTimer = newValue
            if newValue {
                AudioPlayer.shared.playSFX("clockTimer")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    AudioPlayer.shared.stopSFX("clockTimer")
                }
            } else {
                AudioPlayer.shared.stopSFX("clockTimer")
            }
        }
        .animation(
            flashTimer
            ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true)
            : .default,
            value: flashTimer
        )
    }

    private func livesView(isSmall: Bool) -> some View {
        let heartSize: CGFloat = isSmall ? 16 : 18

        return HStack(spacing: 6) {
            ForEach(0..<engine.lives.current, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: heartSize, weight: .bold))
                    .scaleEffect(animateHearts ? 0.75 : 1.0)
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.6),
                        value: animateHearts
                    )
            }
        }
    }

    // MARK: - Event Handlers

    private func handleLivesChange() {
        guard !isRapidMode else { return }

        if engine.lives.current < lastLives {
            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                animateHearts = false
            }

            withAnimation(.easeIn(duration: 0.1)) {
                showLifeLostFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showLifeLostFlash = false
                }
            }

            showFeedback(text: "−1 Life", color: .red)
        }
        lastLives = engine.lives.current
    }

    private func handleScoreChange() {
        if engine.score > lastScore {
            showFeedback(text: "+\(engine.score - lastScore)", color: .green)
        } else if engine.score < lastScore && isRapidMode {
            showFeedback(text: "\(engine.score - lastScore)", color: .red)
        }
        lastScore = engine.score
    }

    private func handleAppear() {
        if isRapidMode {
            AudioPlayer.shared.playMusic("Rapid Theme")
        } else {
            AudioPlayer.shared.playMusic("Classic Theme")
        }

        lastLives = engine.lives.current
        lastScore = engine.score
        showCountdown = true

        loadMyBestScore(leaderboardID: engine.config.leaderboardID) { score in
            bestClassicScore = score
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func showFeedback(text: String, color: Color) {
        feedbackText = text
        feedbackColor = color

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text {
                withAnimation {
                    feedbackText = ""
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Classic Mode") {
    ClassicModeView_iPhone(
        currentScreen: .constant(.classic),
        engine: GameEngine(
            lives: Lives(max: 3),
            colorPool: colorPool,
            config: ModeConfig(
                cardsPerGrid: 6,
                tapTimeLimit: 2.5,
                usesLives: true,
                totalGameTimeLimit: nil,
                leaderboardID: "com.example.ColorAttack.Classic"
            ),
            rules: ClassicRules()
        )
    )
}

#Preview("Rapid Mode") {
    ClassicModeView_iPhone(
        currentScreen: .constant(.rapid),
        engine: GameEngine(
            lives: Lives(max: 1),
            colorPool: colorPool,
            config: ModeConfig(
                cardsPerGrid: 6,
                tapTimeLimit: 120,
                usesLives: false,
                totalGameTimeLimit: 30,
                leaderboardID: "com.example.ColorAttack.Rapid"
            ),
            rules: RapidRules()
        )
    )
}
