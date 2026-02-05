//
//  ClassicModeView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

struct ClassicModeView: View {
    @StateObject var engine: GameEngine
    @State private var bestClassicScore = 0

    @State private var lastLives: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    var body: some View {
        ZStack {
            // Background Image
            GeometryReader { geo in
                Image(engine.remainingGameTime == nil ? "classic_bg" : "rapid_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(x: 1, y: -1)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ZStack {
                VStack(spacing: 24) {
                    Spacer(minLength: 12)

                    // Prompt (Stroop-aware)
                    let isStroop = engine.currentPrompt.displayColor != nil

                    Text(engine.promptText.uppercased())
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(engine.currentPrompt.displayColor?.color ?? .primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    isStroop
                                    ? (
                                        (engine.currentPrompt.displayColor?.color.isLight ?? true)
                                        ? Color.black.opacity(0.75)
                                        : Color.white.opacity(0.75)
                                    )
                                    : engine.switchOn
                                        ? Color.red.opacity(0.25)
                                        : Color.blue.opacity(0.25)
                                )
                        )

                    // Grid of Colors
                    LazyVGrid(columns: columns, spacing: 16) {
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
                    .padding()
                    .frame(maxWidth: 1100)

                    // Tap timer (Classic)
                    if engine.remainingGameTime == nil {
                        let isUrgent = engine.remainingTapTime < 1.0

                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(isUrgent ? .red : .yellow)

                            Text(String(format: "%.1f s", engine.remainingTapTime))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(isUrgent ? .red : .primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isUrgent ? Color.red.opacity(0.2) : Color.black.opacity(0.25))
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

                    Spacer()
                }

                // Game Over Overlay
                if engine.isGameOver {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text("Game Over")
                            .font(.largeTitle)
                            .bold()

                        Text("Final Score: \(engine.score)")
                            .font(.headline)

                        Button("Restart") {
                            engine.restart()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.background)
                    )
                }
            }
        }

        // Header
        .safeAreaInset(edge: .top) {
            ZStack {
                // Mode Label
                HStack {
                    Text(engine.remainingGameTime == nil ? "CLASSIC" : "RAPID")
                        .font(.headline)
                        .foregroundColor(Color.white)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.black.opacity(0.5))
                        )
                    Spacer()
                }

                // Lives/Timer
                if let remaining = engine.remainingGameTime {
                    let isUrgent = remaining <= 5

                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(isUrgent ? .red : .yellow)

                        Text(formatTime(remaining))
                            .font(.title2)
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
                    HStack(spacing: 8) {
                        ForEach(0..<engine.lives.current, id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                                .scaleEffect(animateHearts ? 0.7 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                        }
                    }
                }

                // Score + Best
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(Color.white)

                        Text("\(engine.score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        // ✅ Added from your branch
                        Text("Best: \(bestClassicScore)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.4))
        }

        // Heart loss animation
        .onChange(of: engine.lives.current) {
            if engine.remainingGameTime == nil {
                if engine.lives.current < lastLives {
                    animateHearts = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        animateHearts = false
                    }
                }
                lastLives = engine.lives.current
            }
        }

        // Load best score + start engine
        .onAppear {
            lastLives = engine.lives.current
            engine.start()

            loadMyBestScore(leaderboardID: "com.example.ColorAttack.Classic") { score in
                bestClassicScore = score
            }
        }
        .onDisappear { engine.stop() }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
