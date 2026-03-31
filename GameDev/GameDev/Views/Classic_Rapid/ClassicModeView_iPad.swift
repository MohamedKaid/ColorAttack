//
//  ClassicModeView_iPad.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

struct ClassicModeView_iPad: View {
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
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear
    @State private var leaderboardDetent: PresentationDetent = .medium

    private var backgroundMode: GameBackground.GameMode {
        engine.config.totalGameTimeLimit == nil ? .classic : .rapid
    }

    private var isRapidMode: Bool {
        engine.config.totalGameTimeLimit != nil
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                GameBackground(mode: backgroundMode)
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
            .sheet(isPresented: $showLeaderboard) {
                LeaderBoardView(leaderboardID: engine.config.leaderboardID)
                    .presentationDetents([.medium, .large], selection: $leaderboardDetent)
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: engine.lives.current) { _, _ in handleLivesChange() }
            .onChange(of: engine.score) { _, _ in handleScoreChange() }
            .onAppear { handleAppear() }
            .onDisappear { engine.stop() }
        }
    }

    // MARK: - Main Content

    private func mainContent(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {

            // Left panel — prompt, timer, leaderboard
            // Keep it narrow so the grid gets most of the space
            VStack(spacing: h * 0.04) {
                Spacer()
                promptView(w: w, h: h)
                feedbackToast(w: w)
                if !isRapidMode {
                    tapTimerView(w: w, h: h)
                }
                Spacer()
                leaderboardButton(w: w)
                Spacer(minLength: h * 0.03)
            }
            .frame(width: w * 0.22)
            .padding(.leading, w * 0.02)

            // Right panel — grid fills remaining space
            gridView(w: w, h: h)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, w * 0.02)
        }
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Prompt

    private func promptView(w: CGFloat, h: CGFloat) -> some View {
        let isStroop = engine.currentPrompt.displayColor != nil
        let stroopColor = engine.currentPrompt.displayColor?.color ?? .white
        let isDark = (engine.currentPrompt.displayColor?.color.luminance ?? 1.0) < 0.3

        return Text(engine.promptText.uppercased())
            .font(.system(size: h * 0.048, weight: .heavy))
            .foregroundColor(isStroop ? stroopColor : .white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .lineLimit(2)
            .padding(.vertical, h * 0.02)
            .padding(.horizontal, w * 0.015)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                engine.switchOn ? Color.red.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Feedback Toast

    private func feedbackToast(w: CGFloat) -> some View {
        ZStack {
            if !feedbackText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(feedbackColor)
                        .font(.system(size: 14, weight: .bold))
                    Text(feedbackText)
                        .font(.system(size: 14, weight: .semibold))
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
        .frame(height: 32)
        .animation(.easeOut(duration: 0.2), value: feedbackText)
    }

    // MARK: - Tap Timer

    private func tapTimerView(w: CGFloat, h: CGFloat) -> some View {
        let isUrgent = engine.remainingTapTime < 1.0

        return HStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(isUrgent ? .red : .yellow)
                .font(.system(size: h * 0.028))
            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: h * 0.032, weight: .bold))
                .foregroundColor(isUrgent ? .red : .white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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

    // MARK: - Leaderboard Button

    private func leaderboardButton(w: CGFloat) -> some View {
        Button { showLeaderboard = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                Text("Leaderboard")
                    .fontWeight(.semibold)
            }
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }

    // MARK: - Grid

    private func gridView(w: CGFloat, h: CGFloat) -> some View {
        let isNine = engine.gridColors.count == 9
        let columnCount = 3
        let rowCount = isNine ? 3 : 2
        let spacing: CGFloat = h * 0.03

        // Grid gets w * 0.76 of width (100% - 22% left panel - 2% padding each side)
        let availableW = w * 0.72
        let cardW = (availableW - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        let cardH = cardW * 0.62

        let columns = Array(repeating: GridItem(.fixed(cardW), spacing: spacing), count: columnCount)

        return LazyVGrid(columns: columns, spacing: spacing) {
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
        HStack(spacing: 0) {
            // Back + Best
            Button {
                engine.stop()
                currentScreen = .modeSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: h * 0.03, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, w * 0.02)

            Text("Best: \(bestClassicScore)")
                .font(.system(size: h * 0.03, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 8)

            Spacer()

            // Centre — lives or timer
            if isRapidMode {
                rapidTimer(h: h)
            } else {
                livesView(h: h)
            }

            Spacer()

            // Score + Settings
            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: h * 0.016, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(engine.score)")
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

    private func rapidTimer(h: CGFloat) -> some View {
        let remaining = engine.remainingGameTime ?? engine.config.totalGameTimeLimit ?? 0
        let isUrgent = remaining <= 5

        return HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(isUrgent ? .red : .yellow)
                .font(.system(size: h * 0.032, weight: .bold))
            Text(formatTime(remaining))
                .font(.system(size: h * 0.035, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(flashTimer ? 1.1 : 1.0)
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
            flashTimer ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
            value: flashTimer
        )
    }

    private func livesView(h: CGFloat) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<engine.lives.current, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: h * 0.038, weight: .bold))
                    .scaleEffect(animateHearts ? 0.7 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
            }
        }
    }

    // MARK: - Event Handlers

    private func handleLivesChange() {
        guard !isRapidMode else { return }
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

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func showFeedback(text: String, color: Color) {
        feedbackText = text
        feedbackColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if feedbackText == text { withAnimation { feedbackText = "" } }
        }
    }
}

#Preview("Classic Mode iPad") {
    ClassicModeView_iPad(
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
