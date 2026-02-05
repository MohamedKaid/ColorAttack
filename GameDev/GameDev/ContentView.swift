//
//  ContentView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

struct ContentView: View {

    let colorPool: [GameColor] = [
        GameColor(name: "Red",    color: Color(red: 0.85, green: 0.15, blue: 0.15)),
        GameColor(name: "Blue",   color: Color(red: 0.15, green: 0.45, blue: 0.85)),
        GameColor(name: "Yellow", color: Color(red: 0.95, green: 0.90, blue: 0.20)),
        GameColor(name: "Green",  color: Color(red: 0.20, green: 0.70, blue: 0.30)),
        GameColor(name: "Orange", color: Color(red: 0.95, green: 0.55, blue: 0.15)),
        GameColor(name: "Purple", color: Color(red: 0.60, green: 0.35, blue: 0.75)),
        GameColor(name: "Brown",  color: Color(red: 0.55, green: 0.35, blue: 0.20)),
        GameColor(name: "Black",  color: Color(red: 0.10, green: 0.10, blue: 0.10)),
        GameColor(name: "Pink",   color: Color(red: 0.95, green: 0.50, blue: 0.65))
    ]
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // CLASSIC
                NavigationLink {
                    ClassicModeView(
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
                } label: {
                    modeButtonLabel(icon: "gamecontroller.fill", title: "CLASSIC")
                }
                .buttonStyle(.plain)

                // RAPID
                NavigationLink {
                    ClassicModeView(
                        engine: GameEngine(
                            lives: Lives(max: 1), 
                            colorPool: colorPool,
                            config: ModeConfig(
                                cardsPerGrid: 6,
                                tapTimeLimit: 1.0,
                                usesLives: false,
                                totalGameTimeLimit: 30,
                                leaderboardID: "com.example.ColorAttack.Rapid"
                            ),
                            rules: RapidRules()
                        )
                    )
                } label: {
                    modeButtonLabel(icon: "clock.badge.exclamationmark.fill", title: "RAPID")
                }
                .buttonStyle(.plain)

                // CHAOS
                NavigationLink {
                    ChaosModeView(
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
                } label: {
                    modeButtonLabel(icon: "square.grid.2x2.fill", title: "CHAOS")
                }
                .buttonStyle(.plain)
                
                Button("Leaderboard") {
                    GameCenterUI.showLeaderboards {
                        GameCenterAuth.authenticate()
                    }
                }
            }
            .navigationTitle("Game Modes")
            .padding()
        }
        .onAppear {
            GameCenterAuth.authenticate()
        }
    }

    private func modeButtonLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .tracking(1)
        }
        .foregroundColor(.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 28)
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }
}

#Preview {
    ContentView()
}
