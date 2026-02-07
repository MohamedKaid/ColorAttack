//
//  ModeSelectionView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//
import SwiftUI

struct ModeSelectionView: View {
    @State private var selectedMode: GameMode?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                // Background
                Image("mode_select_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()



                VStack {
                    Spacer(minLength: 40)

                    // Mode Cards ScrollView
                    GeometryReader { geo in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 28) {
                                ForEach(GameMode.allCases) { mode in
                                    ModeCardView(mode: mode) {
                                        selectedMode = mode
                                    }
                                }
                            }
                            .frame(minWidth: geo.size.width) 
                        }
                    }
                    .frame(height: 420)

                    Spacer()

                    // Game Mode Button
                    Text("GAME MODE")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue)
                        )
                        .shadow(radius: 8)

                    Spacer(minLength: 40)
                }
            }
            .navigationDestination(item: $selectedMode) { mode in
                destinationView(for: mode)
            }
        }
    }

    // Game Modes
    @ViewBuilder
    private func destinationView(for mode: GameMode) -> some View {
        switch mode {
        case .classic:
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

        case .rapid:
            ClassicModeView(
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
#Preview("Mode Selection") {
    ModeSelectionPreview()
}


// Preview
private struct ModeSelectionPreview: View {
    @State private var selectedMode: GameMode? = nil
    // Try: .classic, .rapid, .chaos

    var body: some View {
        NavigationStack {
            ModeSelectionView()
        }
    }
}
