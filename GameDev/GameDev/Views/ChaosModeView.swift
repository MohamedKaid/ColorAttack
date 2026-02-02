//
//  ChaosModeView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ChaosModeView: View {
    @StateObject var engine: GameEngine

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

            // MARK: - Main Content
            VStack(spacing: 20) {

                Spacer(minLength: 12)

                // ✅ UPDATED: Color-coded Chaos instructions
                ChaosInstructionView(text: engine.promptText)
                    .padding(.top)

                // Split Screen
                HStack(spacing: 24) {

                    // MARK: - Shapes Side
                    VStack(spacing: 12) {
                        Text("SHAPES")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: shapeColumns, spacing: 16) {
                            ForEach(GameShape.allCases) { shape in
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

                    Divider()

                    // MARK: - Colors Side
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
                .padding(.horizontal)
                .frame(maxWidth: 1200)

                Spacer()
            }

            // MARK: - Top Right HUD
            VStack(alignment: .trailing, spacing: 10) {

                Text("SCORE")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("\(engine.score)")
                    .font(.system(size: 36, weight: .bold))

                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)

                    Text("\(engine.lives.current)")
                        .font(.title2)
                        .bold()
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .shadow(radius: 6)
            .padding()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topTrailing
            )

            // MARK: - Game Over Overlay
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
        .navigationTitle("Chaos")
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }
}

//
// MARK: - Chaos Instruction View
//

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
