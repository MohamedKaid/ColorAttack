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
        isRapidMode ? .rapid : .classic
    }

    private var isRapidMode: Bool {
        engine.config.totalGameTimeLimit != nil
    }

    var body: some View {
        ZStack {
            GameBackground(mode: backgroundMode)
                .ignoresSafeArea()

            if showLifeLostFlash {
                Color.red.opacity(0.25)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // GeometryReader inside ZStack so w/h are safe-area-aware
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
        .sheet(isPresented: $showLeaderboard) {
            CustomLeaderboardView(initialMode: isRapidMode ? .rapid : .classic)
                .presentationDetents([.medium, .large], selection: $leaderboardDetent)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: engine.lives.current) { _, _ in handleLivesChange() }
        .onChange(of: engine.score) { _, _ in handleScoreChange() }
        .onChange(of: engine.isGameOver) { _, isOver in
            guard isOver else { return }
            NotificationManager.shared.handleGameOver(
                score: engine.score,
                mode: isRapidMode ? .rapid : .classic
            )
        }
        .onAppear { handleAppear() }
        .onDisappear { engine.stop() }
    }

    // MARK: - Main Content
    // Landscape: left panel (prompt/timer/leaderboard) | right panel (grid)

    private func mainContent(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {

            // Left panel
            VStack(spacing: 20) {
                Spacer()

                promptView()

                feedbackToast

                if !isRapidMode {
                    tapTimerView
                }


                Spacer(minLength: 20)
            }
            .frame(width: w * 0.24)
            .padding(.leading, 16)
            .padding(.trailing, 8)

            // Right panel — grid
            gridView(w: w, h: h)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
        }
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // MARK: - Prompt

    private func promptView() -> some View {
        let isStroop = engine.currentPrompt.displayColor != nil
        let stroopColor = engine.currentPrompt.displayColor?.color ?? Color.white
        let isDark = (engine.currentPrompt.displayColor?.color.luminance ?? 1.0) < 0.3
        let textColor: Color = isStroop ? stroopColor : .white
        let bgColor: Color = isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.5)
        let borderColor: Color = engine.switchOn ? Color.red.opacity(0.6) : Color.white.opacity(0.2)

        let label = Text(engine.promptText.uppercased())
            .font(.system(size: 36, weight: .heavy))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .lineLimit(2)

        let background = RoundedRectangle(cornerRadius: 16)
            .fill(bgColor)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 2))

        return label
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(background)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
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

    // MARK: - Leaderboard Button

//    private var leaderboardButton: some View {
//        Button { showLeaderboard = true } label: {
//            HStack(spacing: 6) {
//                Image(systemName: "trophy.fill")
//                Text("Leaderboard")
//                    .fontWeight(.semibold)
//            }
//            .font(.system(size: 14))
//            .padding(.horizontal, 18)
//            .padding(.vertical, 11)
//            .frame(maxWidth: .infinity)
//            .background(
//                LinearGradient(
//                    colors: [.purple, .blue],
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//            )
//            .foregroundColor(.white)
//            .clipShape(Capsule())
//            .shadow(color: .purple.opacity(0.4), radius: 6, y: 3)
//        }
//    }

    // MARK: - Grid

    private func gridView(w: CGFloat, h: CGFloat) -> some View {
        let columnCount = 3
        let spacing: CGFloat = 14
        // Available width = full width minus left panel (24%) and paddings
        let availableW = w * 0.72
        let cardW = (availableW - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)

        // In landscape h is short — fit 2 rows comfortably
        let rowCount: CGFloat = engine.gridColors.count == 9 ? 3 : 2
        let availableH = h - 32 // small top/bottom breathing room
        let maxCardH = (availableH - spacing * (rowCount - 1)) / rowCount
        let cardH = min(cardW * 0.65, maxCardH)

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
        .frame(maxHeight: .infinity, alignment: .center)
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
                Text(isRapidMode ? "Time's Up!" : "Game Over")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.white)

                Text("Final Score: \(engine.score)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                Text("Best: \(bestClassicScore)")
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
                    .tint(isRapidMode ? .red : .yellow)
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

    private func header(w: CGFloat) -> some View {
        HStack(spacing: 8) {

            // Back button
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

            // Best score
            VStack(alignment: .leading, spacing: 1) {
                Text("Best")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(bestClassicScore)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Centre — lives or rapid timer
            if isRapidMode {
                rapidTimer
            } else {
                livesView
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 1) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(engine.score)")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
            }

            // Settings button
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

    // MARK: - Rapid Timer

    private var rapidTimer: some View {
        let remaining = engine.remainingGameTime ?? engine.config.totalGameTimeLimit ?? 0
        let isUrgent = remaining <= 5

        return HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .foregroundColor(isUrgent ? .red : .yellow)
                .font(.system(size: 16))
            Text(formatTime(remaining))
                .font(.system(size: 18, weight: .bold))
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
            flashTimer ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
            value: flashTimer
        )
    }

    // MARK: - Lives View

    private var livesView: some View {
        HStack(spacing: 8) {
            ForEach(0..<engine.lives.current, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20, weight: .bold))
                    .scaleEffect(animateHearts ? 0.72 : 1.0)
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

// MARK: - Previews

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

#Preview("Rapid Mode iPad") {
    ClassicModeView_iPad(
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
