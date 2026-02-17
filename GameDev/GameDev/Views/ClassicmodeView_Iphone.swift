//
//  ClassicmodeView_Iphone.swift
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

    // Feedback states
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    private var isRapidMode: Bool { engine.config.totalGameTimeLimit != nil }

    private var backgroundMode: GameBackground.GameMode {
        isRapidMode ? .rapid : .classic
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let layout = layout(for: width)

            ZStack {
                backgroundLayer

                // Life-lost red flash overlay
                if showLifeLostFlash {
                    Color.red
                        .opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                mainContent(width: width, layout: layout)

                overlays
            }
            .safeAreaInset(edge: .top) {
                phoneHeader(width: width)
            }
            .onChange(of: engine.lives.current) {
                handleLivesChange()
            }
            .onChange(of: engine.score) {
                handleScoreChange()
            }
            .onAppear {
                handleAppear()
            }
            .onDisappear {
                engine.stop()
            }
        }
    }

    private struct PhoneLayout {
        let columns: [GridItem]
        let spacing: CGFloat
    }

    private func layout(for width: CGFloat) -> PhoneLayout {
        let count = width < 380 ? 2 : 3
        let spacing: CGFloat = width < 380 ? 10 : 12
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
        return PhoneLayout(columns: columns, spacing: spacing)
    }

    private var backgroundLayer: some View {
        GameBackground(mode: backgroundMode)
            .ignoresSafeArea()
    }

    private func mainContent(width: CGFloat, layout: PhoneLayout) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 8)

            promptView(width: width)

            // Feedback toast
            feedbackToast

            if !isRapidMode {
                tapTimerView
            }

            gridView(layout: layout)

            Spacer(minLength: 8)
        }
        .blur(radius: showCountdown || showSettings ? 8 : 0)
        .allowsHitTesting(!showCountdown && !showSettings)
    }

    // Feedback Toast

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
                        .overlay(
                            Capsule()
                                .stroke(feedbackColor.opacity(0.5), lineWidth: 1)
                        )
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

    // Prompt

    private func promptView(width: CGFloat) -> some View {
        let isStroop = engine.currentPrompt.displayColor != nil
        let stroopColor = engine.currentPrompt.displayColor?.color ?? .white
        let luminance = engine.currentPrompt.displayColor?.color.luminance ?? 1.0
        let isDark = luminance < 0.3

        return Text(engine.promptText.uppercased())
            .font(.system(size: width < 380 ? 22 : 26, weight: .heavy))
            .foregroundColor(isStroop ? stroopColor : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(promptBackground(isDark: isDark))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }

    private func promptBackground(isDark: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        engine.switchOn ? Color.red.opacity(0.6) : Color.white.opacity(0.18),
                        lineWidth: 2
                    )
            )
    }

    // Tap Timer

    private var tapTimerView: some View {
        let isUrgent = engine.remainingTapTime < 1.0

        return HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(isUrgent ? .red : .yellow)

            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isUrgent ? .red : .white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isUrgent ? Color.red.opacity(0.28) : Color.black.opacity(0.38))
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
        .scaleEffect(flashTimer ? 1.08 : 1.0)
        .onChange(of: isUrgent) { flashTimer = isUrgent }
        .animation(
            flashTimer ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true) : .default,
            value: flashTimer
        )
    }

    // Grid

    private func gridView(layout: PhoneLayout) -> some View {
        let isNine = engine.gridColors.count == 9
        let gridSpacing: CGFloat = isNine ? 12 : 16

        return LazyVGrid(columns: layout.columns, spacing: gridSpacing) {
            ForEach(engine.gridColors) { gameColor in
                Button {
                    engine.handleTap(action: .colorTap(gameColor))
                } label: {
                    CardView(gameColor: gameColor)
                }
                .buttonStyle(.plain)
                .disabled(engine.isGameOver)
            }
        }
        .padding(isNine ? 10 : 16)
        .frame(maxWidth: 1100)
    }

    // Overlays

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

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Game Over")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)

                Text("Final Score: \(engine.score)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 12) {
                    Button("Home") {
                        engine.stop()
                        currentScreen = .modeSelection
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 18)
        }
    }

    // Header

    @ViewBuilder
    private func phoneHeader(width: CGFloat) -> some View {
        let titleSize: CGFloat = width < 380 ? 16 : 18
        let valueSize: CGFloat = width < 380 ? 18 : 20

        HStack(spacing: 10) {
            Button {
                engine.stop()
                currentScreen = .modeSelection
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Score to Beat")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(bestClassicScore)")
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            centerStatus(valueSize: valueSize)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(engine.score)")
                    .font(.system(size: valueSize, weight: .heavy))
                    .foregroundColor(.white)
            }

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSettings = true
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
    }

    @ViewBuilder
    private func centerStatus(valueSize: CGFloat) -> some View {
        if isRapidMode {
            let remaining = engine.remainingGameTime ?? engine.config.totalGameTimeLimit ?? 0
            let isUrgent = remaining <= 5

            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(isUrgent ? .red : .yellow)
                Text(formatTime(remaining))
                    .font(.system(size: valueSize, weight: .heavy))
                    .foregroundColor(.white)
            }
            .scaleEffect(flashTimer ? 1.08 : 1.0)
            .onChange(of: isUrgent) { flashTimer = isUrgent }
            .animation(
                flashTimer ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true) : .default,
                value: flashTimer
            )
        } else {
            HStack(spacing: 6) {
                ForEach(0..<engine.lives.current, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 18, weight: .bold))
                        .scaleEffect(animateHearts ? 0.75 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }
        }
    }

    // Event Handlers

    private func handleLivesChange() {
        if engine.lives.current < lastLives {
            // Heart shrink
            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                animateHearts = false
            }

            // Red flash
            withAnimation(.easeIn(duration: 0.1)) {
                showLifeLostFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showLifeLostFlash = false
                }
            }

            // Toast
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

        let leaderboardID = isRapidMode
            ? "com.example.ColorAttack.Rapid"
            : "com.example.ColorAttack.Classic"

        loadMyBestScore(leaderboardID: leaderboardID) { score in
            bestClassicScore = score
        }
    }

    // Helpers

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


#Preview("Classic Mode") {
    ClassicModeView(
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
    ClassicModeView(
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
