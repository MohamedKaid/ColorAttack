//
//  ContentView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

let colorPool: [GameColor] = [
    // Saturated, distinct colors that pop on dark backgrounds
    GameColor(name: "Red",    color: Color(red: 0.90, green: 0.25, blue: 0.25)),
    GameColor(name: "Blue",   color: Color(red: 0.25, green: 0.50, blue: 0.95)),
    GameColor(name: "Yellow", color: Color(red: 0.80, green: 0.68, blue: 0.00)),
    GameColor(name: "Green",  color: Color(red: 0.30, green: 0.75, blue: 0.40)),
    GameColor(name: "Orange", color: Color(red: 0.95, green: 0.55, blue: 0.20)),
    GameColor(name: "Purple", color: Color(red: 0.65, green: 0.40, blue: 0.85)),
    GameColor(name: "Brown",  color: Color(red: 0.60, green: 0.40, blue: 0.25)),
    GameColor(name: "Black",  color: Color(red: 0.15, green: 0.15, blue: 0.18)),
    GameColor(name: "Pink",   color: Color(red: 0.95, green: 0.45, blue: 0.60))
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
        }
    }
}


//import SwiftUI
//import UIKit // UIFont is part of UIKit
//
//struct ContentView: View {
//    var body: some View {
//        Text("Printing all available fonts to the console...")
//            .onAppear {
//                printAllFonts()
//            }
//    }
//
//    func printAllFonts() {
//        for familyName in UIFont.familyNames.sorted() {
//            print("Family: \(familyName)")
//            let names = UIFont.fontNames(forFamilyName: familyName)
//            for fontName in names {
//                print("  - \(fontName)")
//            }
//        }
//    }
//}

#Preview {
    ContentView()
}
