//
//  ContentView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

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

struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartView()
        }
        .onAppear {
            GameCenterAuth.authenticate()
        }
    }
}

#Preview {
    ContentView()
}

//struct ContentView: View {
////    let AccessibilityColorPool: [GameColor] = [
////        GameColor(name: "Blue",     color: Color(red: 0.00, green: 0.45, blue: 0.70)),
////        GameColor(name: "Orange",   color: Color(red: 0.90, green: 0.60, blue: 0.00)),
////        GameColor(name: "Sky Blue", color: Color(red: 0.35, green: 0.70, blue: 0.90)),
////        GameColor(name: "Bluish Green", color: Color(red: 0.00, green: 0.60, blue: 0.50)),
////        GameColor(name: "Yellow",   color: Color(red: 0.95, green: 0.90, blue: 0.25)),
////        GameColor(name: "Vermillion", color: Color(red: 0.80, green: 0.40, blue: 0.00)),
////        GameColor(name: "Reddish Purple", color: Color(red: 0.80, green: 0.60, blue: 0.70)),
////        GameColor(name: "Gray",     color: Color(red: 0.60, green: 0.60, blue: 0.60))
////    ]
//
//
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//
//                NavigationLink {
//                    ClassicModeView(
//                        engine: GameEngine(
//                            lives: Lives(max: 3),
//                            colorPool: colorPool,
//                            rules: ClassicRules()
//                        )
//                    )
//                } label: {
//                    HStack(spacing: 10) {
//                        Image(systemName: "gamecontroller.fill")
//                            .font(.title3)
//
//                        Text("CLASSIC")
//                            .font(.system(size: 20, weight: .bold, design: .rounded))
//                            .tracking(1)
//                    }
//                    .foregroundColor(.white)
//                    .padding(.vertical, 14)
//                    .padding(.horizontal, 28)
//                    .background(
//                        LinearGradient(
//                            colors: [.blue, .purple],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
//                }
//                .buttonStyle(.plain)
//
//
//                NavigationLink{
//                    ClassicModeView(
//                        engine: GameEngine(
//                            lives: Lives(max: 1), // irrelevant because usesLives = false
//                            colorPool: colorPool,
//                            config: ModeConfig(
//                                cardsPerGrid: 6,
//                                tapTimeLimit: 120,
//                                usesLives: false,
//                                totalGameTimeLimit: 30 // 2 minutes
//                            ),
//                            rules: RapidRules()
//                        )
//                    )
//                }label: {
//                    HStack(spacing: 10) {
//                        Image(systemName: "clock.badge.exclamationmark.fill")
//                            .font(.title3)
//
//                        Text("RAPID")
//                            .font(.system(size: 20, weight: .bold, design: .rounded))
//                            .tracking(1)
//                    }
//                    .foregroundColor(.white)
//                    .padding(.vertical, 14)
//                    .padding(.horizontal, 28)
//                    .background(
//                        LinearGradient(
//                            colors: [.blue, .purple],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
//                }
//                .buttonStyle(.plain)
//                .buttonStyle(.borderedProminent)
//                
//                NavigationLink {
//                    ChaosModeView(
//                        engine: GameEngine(
//                            lives: Lives(max: 5), // Chaos is harder
//                            colorPool: colorPool,
//                            config: ModeConfig(
//                                cardsPerGrid: 6,
//                                tapTimeLimit: 2.5,
//                                usesLives: true
//                            ),
//                            rules: ChaosRules()
//                        )
//                    )
//                } label: {
//                    HStack(spacing: 10) {
//                        Image(systemName: "square.grid.2x2.fill")
//                            .font(.title3)
//
//                        Text("CHAOS")
//                            .font(.system(size: 20, weight: .bold, design: .rounded))
//                            .tracking(1)
//                    }
//                    .foregroundColor(.white)
//                    .padding(.vertical, 14)
//                    .padding(.horizontal, 28)
//                    .background(
//                        LinearGradient(
//                            colors: [.blue, .purple],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//                    .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
//                }
//                .buttonStyle(.plain)
//
//            }
//            .font(.title2)
//            .navigationTitle("Game Modes")
//            .padding()
//        }
//    }
//}

