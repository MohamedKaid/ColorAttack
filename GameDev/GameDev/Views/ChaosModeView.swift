//
//  ChaosModeView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ChaosModeView: View {
    @StateObject var engine: GameEngine

    @State private var swapSides = false
    @State private var lastLives: Int = 0
    @State private var animateHearts = false
    @State private var flashTimer = false

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
            GeometryReader { geo in
                Image("chaos_bg")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(x: 1, y: -1)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ZStack {

                VStack(spacing: 24) {

                    Spacer(minLength: 12)

                    // Instructions
                    ChaosInstructionView(text: engine.promptText)
                        .padding(.top)

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

                    // Tap Timer(flashes under 1.0)
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
                    Text("CHAOS")
                        .font(.headline)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                    Spacer()
                }

                // Lives
                HStack(spacing: 8) {
                    ForEach(0..<engine.lives.current, id: \.self) { _ in
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title2)
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
                            .foregroundColor(.secondary)

                        Text("\(engine.score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.4)
            )
        }

        // Swaps sides after round 12
        .onChange(of: engine.round) {
            if engine.round >= 12 {
                swapSides = Bool.random()
            } else {
                swapSides = false
            }
        }
        .onChange(of: engine.lives.current) {
            if engine.lives.current < lastLives {
                animateHearts = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    animateHearts = false
                }
            }
            lastLives = engine.lives.current
        }

        .onAppear {
            lastLives = engine.lives.current
            engine.start()
        }
        .onDisappear { engine.stop() }
    }

    // Color Column
    private var colorsColumn: some View {
        VStack(spacing: 12) {
            Text("COLORS")
                .font(.headline)
                .foregroundColor(.secondary)

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
                .foregroundColor(.secondary)

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

#Preview {
    ChaosModeView(
        engine: GameEngine(
            lives: Lives(max: 5),
            colorPool: colorPool,
            rules: ChaosRules()
        )
    )
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
                    .bold()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor(for: line))
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
