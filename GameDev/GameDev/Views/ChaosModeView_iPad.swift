//
//  ChaosModeView.swift
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

    // Feedback states
    @State private var showLifeLostFlash = false
    @State private var feedbackText: String = ""
    @State private var feedbackColor: Color = .clear

    private let colorColumns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    private let shapeColumns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 2
    )

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: .chaos)
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

                    // Instructions
                    ChaosInstructionView(text: engine.promptText)
                        .padding(.top)

                    // Feedback toast
                    feedbackToast

                    // Tap Timer (flashes under 1.0)
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

                    // Split screen (with swap)
                    HStack(spacing: 24) {
                        if swapSides {
                            shapesColumn
                            colorsColumn
                        } else {
                            colorsColumn
                            shapesColumn
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 1200)
                    .animation(.easeInOut(duration: 0.25), value: swapSides)

                    Spacer()
                }

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

                        Button("Home") {
                            engine.stop()
                            currentScreen = .modeSelection
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
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

            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }

        // Header
        .safeAreaInset(edge: .top) {
            ZStack {
                // Mode Label
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

                // Lives
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

                // Score
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

        // Swaps sides after round 12
        .onChange(of: engine.round) {
            if engine.round >= 12 {
                swapSides = Bool.random()
            } else {
                swapSides = false
            }
        }

        // Life Lost Feedback
        .onChange(of: engine.lives.current) {
            if engine.lives.current < lastLives {
                // Heart shrink
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

        // Score Change Feedback
        .onChange(of: engine.score) {
            if engine.score > lastScore {
                showFeedback(text: "+\(engine.score - lastScore)", color: .green)
            } else if engine.score < lastScore {
                showFeedback(text: "\(engine.score - lastScore)", color: .red)
            }
            lastScore = engine.score
        }

        .onAppear {
            lastLives = engine.lives.current
            lastScore = engine.score
            showCountdown = true

            let leaderboardID = "com.example.ColorAttack.Chaos"

            loadMyBestScore(leaderboardID: leaderboardID) { score in
                bestClassicScore = score
            }
        }
        .onDisappear { engine.stop() }
    }

    // Feedback Toast

    private var feedbackToast: some View {
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
    }

    // Helpers

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

    // Color Column
    private var colorsColumn: some View {
        VStack(spacing: 12) {
            Text("COLORS")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(columns: colorColumns, spacing: 16) {
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
        }
        .frame(maxWidth: .infinity)
    }

    // Shapes Column
    private var shapesColumn: some View {
        VStack(spacing: 12) {
            Text("SHAPES")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(columns: shapeColumns, spacing: 16) {
                ForEach(engine.gridShapes) { shape in
                    Button {
                        engine.handleTap(action: .shapeTap(shape))
                    } label: {
                        ShapeCardView(shape: shape)
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.isGameOver)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChaosInstructionView: View {
    let text: String

    var body: some View {
        let lines = text
            .split(separator: "\n")
            .map(String.init)

        VStack(spacing: 12) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.title2)
                    .foregroundColor(.white)
                    .bold()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor(for: line))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private func backgroundColor(for line: String) -> Color {
        if line.contains("DON'T TAP") {
            return Color.red.opacity(0.35)
        } else {
            return Color.blue.opacity(0.35)
        }
    }
}

#Preview("Chaos Mode") {
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
