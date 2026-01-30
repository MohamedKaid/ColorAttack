//
//  ClassicModeView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

struct ClassicModeView: View {
    @StateObject var engine: GameEngine

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 3
    )

    var body: some View {
        ZStack {
            VStack(spacing: 24) {

                Spacer(minLength: 12)

                // Prompt (centered & dominant)
                Text(engine.promptText.uppercased())
                    .font(.largeTitle)
                    .bold()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                engine.switchOn
                                ? Color.red.opacity(0.25)
                                : Color.blue.opacity(0.25)
                            )
                    )

                // Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(engine.gridColors) { gameColor in
                        Button {
                            engine.handleTap(on: gameColor)
                        } label: {
                            CardView(gameColor: gameColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(engine.isGameOver)
                    }
                }
                .padding()
                .frame(maxWidth: 1100)

                Spacer()
            }
            
            
            VStack(alignment: .trailing, spacing: 10) {

                Text("SCORE")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("\(engine.score)")
                    .font(.system(size: 36, weight: .bold))

                if engine.remainingGameTime == nil {
                    HStack(spacing: 8) {
                        Text("\(engine.lives.current)")
                            .font(.title2)
                            .bold()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                    HStack(spacing: 8) {
                        Text(String(format: "%.1f", engine.remainingTapTime))
                            .font(.title2)
                            .bold()
                        
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                } else if let remaining = engine.remainingGameTime {
                    Text(formatTime(remaining))
                        .font(.title2)
                        .bold()
                }

            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12))
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .padding()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topTrailing
            )

            
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
        .navigationTitle("Mode")
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}



