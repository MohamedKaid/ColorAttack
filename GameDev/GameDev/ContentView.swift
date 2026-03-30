//
//  ContentView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

let colorPool: [GameColor] = [
    GameColor(name: "Red",    color: Color(hex: "E64040")),
    GameColor(name: "Blue",   color: Color(hex: "4080F2")),
    GameColor(name: "Yellow", color: Color(hex: "CCAD00")),
    GameColor(name: "Green",  color: Color(hex: "4DBF66")),
    GameColor(name: "Orange", color: Color(hex: "F28C33")),
    GameColor(name: "Purple", color: Color(hex: "A666D9")),
    GameColor(name: "Brown",  color: Color(hex: "996640")),
    GameColor(name: "Black",  color: Color(hex: "26262E")),
    GameColor(name: "Pink",   color: Color(hex: "F27399"))
]

struct ContentView: View {
    @State private var currentScreen: AppScreen = .start

    var body: some View {
        switch currentScreen {
        case .start:
            StartView(currentScreen: $currentScreen)
                .onAppear {
                    GameCenterAuth.authenticate()
                }

        case .modeSelection:
            ModeSelectionView(currentScreen: $currentScreen)

        case .classic:
            ClassicModeView(
                currentScreen: $currentScreen,
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

        case .rapid:
            ClassicModeView(
                currentScreen: $currentScreen,
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

        case .chaos:
            ChaosModeView(
                currentScreen: $currentScreen,
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

        case .sequence:
            // TODO: Replace leaderboardID with real Game Center ID once created
            SequenceModeView(
                currentScreen: $currentScreen,
                engine: GameEngine(
                    lives: Lives(max: 5),
                    colorPool: colorPool,
                    config: ModeConfig(
                        cardsPerGrid: 12,
                        tapTimeLimit: 999,
                        usesLives: true,
                        totalGameTimeLimit: nil,
                        leaderboardID: "com.example.ColorAttack.Sequence"
                    ),
                    rules: nil
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
