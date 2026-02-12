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

    @State private var bestChaosScore = 0
    @State private var lastLives: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false
    @State private var showCountdown = true

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let shapeColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        ZStack {
            GameBackground(mode: .chaos)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer(minLength: 6)

                ChaosInstructionView(text: engine.promptText)
                    .padding(.top, 4)

                // Tap timer (flashes under 1.0)
                tapTimerPill

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        VStack(spacing: 10) {
                            sectionHeader("COLORS")
                            LazyVGrid(columns: colorColumns, spacing: 12) {
                                ForEach(engine.gridColors) { gameColor in
                                    Button {
                                        engine.handleTap(action: .colorTap(gameColor))
                                    } label: {
                                        CardView(gameColor: gameColor)
                                            .aspectRatio(1, contentMode: .fit)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(engine.isGameOver)
                                }
                            }
                        }

                        VStack(spacing: 10) {
                            sectionHeader("SHAPES")
                            LazyVGrid(columns: shapeColumns, spacing: 12) {
                                ForEach(engine.gridShapes) { shape in
                                    Button {
                                        engine.handleTap(action: .shapeTap(shape))
                                    } label: {
                                        ShapeCardView(shape: shape)
                                            .aspectRatio(1, contentMode: .fit)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(engine.isGameOver)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }

                Spacer(minLength: 6)
            }
            .blur(radius: showCountdown ? 8 : 0)
            .allowsHitTesting(!showCountdown)

            if engine.isGameOver {
                gameOverOverlay
            }

            if showCountdown {
                CountdownView {
                    showCountdown = false
                    engine.start()
                }
            }
        }
        .safeAreaInset(edge: .top) { phoneHeader }
        .onChange(of: engine.lives.current) { handleLivesChange() }
        .onAppear { handleAppear() }
        .onDisappear { engine.stop() }
    }

    // MARK: - UI bits

    private var phoneHeader: some View {
        HStack {
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

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<engine.lives.current, id: \.self) { _ in
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20, weight: .bold))
                        .scaleEffect(animateHearts ? 0.75 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: animateHearts)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(engine.score)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)

                Text("Best: \(bestChaosScore)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
    }

    private var tapTimerPill: some View {
        let isUrgent = engine.remainingTapTime < 1.0

        return HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(isUrgent ? .red : .yellow)

            Text(String(format: "%.1f s", engine.remainingTapTime))
                .font(.system(size: 20, weight: .bold))
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

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.75))
            Spacer()
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
                    .tint(.white)

                    Button("Restart") {
                        showCountdown = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
            )
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Logic
    private func handleLivesChange() {
        if engine.lives.current < lastLives {
            animateHearts = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                animateHearts = false
            }
        }
        lastLives = engine.lives.current
    }

    private func handleAppear() {
        lastLives = engine.lives.current
        showCountdown = true

        let leaderboardID = "com.example.ColorAttack.Chaos"
        loadMyBestScore(leaderboardID: leaderboardID) { score in
            bestChaosScore = score
        }
    }
}
