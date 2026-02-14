//
//  ClassicModeView.swift
//  GameDev
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
    
    // Feedback states
    @State private var showLifeLostFlash = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showCorrectIndicator = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    private var backgroundMode: GameBackground.GameMode {
        engine.config.totalGameTimeLimit == nil ? .classic : .rapid
    }
    
    private var isRapidMode: Bool {
        engine.config.totalGameTimeLimit != nil
    }

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: backgroundMode)
                .ignoresSafeArea()

            // Life-lost red flash overlay
            if showLifeLostFlash {
                Color.red
                    .opacity(0.25)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // Game content
            ZStack {
                VStack(spacing: 24) {
                    Spacer(minLength: 12)

                    // Prompt (Stroop-aware)
                    let isStroop = engine.currentPrompt.displayColor != nil
                    let stroopColor = engine.currentPrompt.displayColor?.color ?? .white
                    let isStroopColorDark = (engine.currentPrompt.displayColor?.color.luminance ?? 1.0) < 0.3
                    
                    Text(engine.promptText.uppercased())
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(
                            isStroop ? stroopColor : .white
                        )
                        .padding(.vertical, 12)
                        .padding(.horizontal, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    isStroop && isStroopColorDark
                                    ? Color.white.opacity(0.9)
                                    : Color.black.opacity(0.5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            engine.switchOn
                                            ? Color.red.opacity(0.6)
                                            : isStroopColorDark
                                            ? Color.black.opacity(0.3)
                                            : Color.white.opacity(0.2),
                                            lineWidth: 2
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                    // Feedback toast (correct / wrong)
                    ZStack {
                        if !feedbackText.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: feedbackColor == .green ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(feedbackColor)
                                Text(feedbackText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
                    .frame(height: 36)
                    .animation(.easeOut(duration: 0.2), value: feedbackText)

                    // Tap timer (Classic only)
                    if !isRapidMode {
                        let isUrgent = engine.remainingTapTime < 1.0

                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(isUrgent ? .red : .yellow)

                            Text(String(format: "%.1f s", engine.remainingTapTime))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(isUrgent ? .red : .white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isUrgent ? Color.red.opacity(0.3) : Color.black.opacity(0.4))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .scaleEffect(flashTimer ? 1.15 : 1.0)
                        .onChange(of: isUrgent) { flashTimer = isUrgent }
                        .animation(
                            flashTimer
                            ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                            : .default,
                            value: flashTimer
                        )
                    }
                    
                    // Grid of Colors
                    let isNine = engine.gridColors.count == 9
                    let gridSpacing: CGFloat = isNine ? 12 : 16

                    LazyVGrid(columns: columns, spacing: gridSpacing) {
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
                    Spacer()
                }
                .offset(x: shakeOffset)

                // Game Over Overlay
                if engine.isGameOver {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text("Game Over")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)

                        Text("Final Score: \(engine.score)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        HStack(spacing: 16) {
                            Button("Home") {
                                engine.stop()
                                currentScreen = .modeSelection
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .blur(radius: showCountdown || showSettings ? 8 : 0)
            .allowsHitTesting(!showCountdown && !showSettings)

            // Countdown overlay
            if showCountdown {
                CountdownView {
                    showCountdown = false
                    engine.start()
                }
            }
            
            // Settings popup overlay
            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }

        // Header
        .safeAreaInset(edge: .top) {
            ZStack {
                // Mode label
                HStack {
                    Button {
                        engine.stop()
                        currentScreen = .modeSelection
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Text("Score to Beat: \(bestClassicScore)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }

                // Lives/Timer center
                if isRapidMode {
                    let remaining = engine.remainingGameTime ?? engine.config.totalGameTimeLimit ?? 0
                    let isUrgent = remaining <= 5
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(isUrgent ? .red : .yellow)
                            .font(.system(size: 36, weight: .bold))
                        Text(formatTime(remaining))
                            .font(.system(size: 36, weight: .bold))
                            .bold()
                            .foregroundColor(.white)
                    }
                    .scaleEffect(flashTimer ? 1.15 : 1.0)
                    .onChange(of: isUrgent) { flashTimer = isUrgent }
                    .animation(
                        flashTimer
                        ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                        : .default,
                        value: flashTimer
                    )
                } else {
                    HStack(spacing: 12) {
                        ForEach(0..<engine.lives.current, id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 36, weight: .bold))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .scaleEffect(animateHearts ? 0.7 : 1.0)
                                .animation(
                                    .spring(response: 0.25, dampingFraction: 0.6),
                                    value: animateHearts
                                )
                        }
                    }
                }

                // Score and Settings
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(engine.score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.5))
        }

        // MARK: - Life Lost Feedback
        .onChange(of: engine.lives.current) {
            if !isRapidMode {
                if engine.lives.current < lastLives {
                    // Heart shrink animation
                    animateHearts = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
        }

        // MARK: - Score Change Feedback
        .onChange(of: engine.score) {
            if engine.score > lastScore {
                showFeedback(text: "+\(engine.score - lastScore)", color: .green)
            } else if engine.score < lastScore && isRapidMode {
                showFeedback(text: "\(engine.score - lastScore)", color: .red)
                
                // Shake on wrong tap in rapid too
            }
            lastScore = engine.score
        }

        // Load best score
        .onAppear {
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
        .onDisappear { engine.stop() }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
    /// Shows a brief feedback toast that auto-dismisses
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
