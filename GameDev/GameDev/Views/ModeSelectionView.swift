////
////  ModeSelectionView.swift
////  GameDev
////
////  Created by Mohamed Shahbain on 2/4/26.
////
//import SwiftUI
//
//struct ModeSelectionView: View {
//    @State private var selectedMode: GameMode?
//
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                
//                // Background
//                Image("mode_select_bg")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: geo.size.width, height: geo.size.height)
//
//
//
//                VStack {
//                    Spacer(minLength: 40)
//
//                    // Mode Cards ScrollView
//                    GeometryReader { geo in
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 28) {
//                                ForEach(GameMode.allCases) { mode in
//                                    ModeCardView(mode: mode) {
//                                        selectedMode = mode
//                                    }
//                                }
//                            }
//                            .frame(minWidth: geo.size.width)
//                        }
//                    }
//                    .frame(height: 420)
//
//                    Spacer()
//
//                    // Game Mode Button
//                    Text("GAME MODE")
//                        .font(.title2)
//                        .bold()
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 36)
//                        .padding(.vertical, 14)
//                        .background(
//                            RoundedRectangle(cornerRadius: 14)
//                                .fill(Color.blue)
//                        )
//                        .shadow(radius: 8)
//
//                    Spacer(minLength: 40)
//                }
//            }
//            .navigationDestination(item: $selectedMode) { mode in
//                destinationView(for: mode)
//            }
//        }
//        .ignoresSafeArea()
//    }
//
//    // Game Modes
//    @ViewBuilder
//    private func destinationView(for mode: GameMode) -> some View {
//        switch mode {
//        case .classic:
//            ClassicModeView(
//                engine: GameEngine(
//                    lives: Lives(max: 3),
//                    colorPool: colorPool,
//                    config: ModeConfig(
//                        cardsPerGrid: 6,
//                        tapTimeLimit: 2.5,
//                        usesLives: true,
//                        totalGameTimeLimit: nil,
//                        leaderboardID: "com.example.ColorAttack.Classic"
//                    ),
//                    rules: ClassicRules()
//                )
//            )
//
//        case .rapid:
//            ClassicModeView(
//                engine: GameEngine(
//                    lives: Lives(max: 1),
//                    colorPool: colorPool,
//                    config: ModeConfig(
//                        cardsPerGrid: 6,
//                        tapTimeLimit: 120,
//                        usesLives: false,
//                        totalGameTimeLimit: 30,
//                        leaderboardID: "com.example.ColorAttack.Rapid"
//                    ),
//                    rules: RapidRules()
//                )
//            )
//
//        case .chaos:
//            ChaosModeView(
//                engine: GameEngine(
//                    lives: Lives(max: 5),
//                    colorPool: colorPool,
//                    config: ModeConfig(
//                        cardsPerGrid: 6,
//                        tapTimeLimit: 2.5,
//                        usesLives: true,
//                        totalGameTimeLimit: nil,
//                        leaderboardID: "com.example.ColorAttack.Chaos"
//                    ),
//                    rules: ChaosRules()
//                )
//            )
//        }
//    }
//}
//#Preview("Mode Selection") {
//    ModeSelectionPreview()
//}
//
//
//// Preview
//private struct ModeSelectionPreview: View {
//    @State private var selectedMode: GameMode? = nil
//    // Try: .classic, .rapid, .chaos
//
//    var body: some View {
//        NavigationStack {
//            ModeSelectionView()
//        }
//    }
//}


//
//  ModeSelectionView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @State private var selectedMode: GameMode?
    @State private var currentIndex: Int = 0
    @State private var dragX: CGFloat = 0   // ✅ NEW

    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 20

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: .menu)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 60)

                // Title
                Text("SELECT MODE")
                    .font(.custom("Candy-Planet", size: 32))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                Spacer(minLength: 40)

                // ✅ Carousel (replaces the ScrollView block only)
                ZStack {
                    let modes = GameMode.allCases
                    let count = modes.count
                    let sideOffset = cardWidth + cardSpacing

                    // Left card
                    ModeCardView(
                        mode: modes[wrappedIndex(currentIndex - 1, count)],
                        isSelected: false,
                        onStart: { selectedMode = modes[wrappedIndex(currentIndex - 1, count)] }
                    )
                    .frame(width: cardWidth, height: 480)
                    .scaleEffect(0.88)
                    .opacity(0.55)
                    .offset(x: -sideOffset + dragX * 0.35)
                    .allowsHitTesting(false)

                    // Right card
                    ModeCardView(
                        mode: modes[wrappedIndex(currentIndex + 1, count)],
                        isSelected: false,
                        onStart: { selectedMode = modes[wrappedIndex(currentIndex + 1, count)] }
                    )
                    .frame(width: cardWidth, height: 480)
                    .scaleEffect(0.88)
                    .opacity(0.55)
                    .offset(x: sideOffset + dragX * 0.35)
                    .allowsHitTesting(false)

                    // Center card
                    ModeCardView(
                        mode: modes[currentIndex],
                        isSelected: true,
                        onStart: { selectedMode = modes[currentIndex] }
                    )
                    .frame(width: cardWidth, height: 480)
                    .offset(x: dragX)
                }
                .frame(height: 500)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragX = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 90
                            let predicted = value.predictedEndTranslation.width
                            let generator = UIImpactFeedbackGenerator(style: .light)

                            if predicted < -threshold {
                                // swipe left -> next
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentIndex = wrappedIndex(currentIndex + 1, GameMode.allCases.count)
                                }
                                generator.impactOccurred()
                            } else if predicted > threshold {
                                // swipe right -> prev
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentIndex = wrappedIndex(currentIndex - 1, GameMode.allCases.count)
                                }
                                generator.impactOccurred()
                            }

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                dragX = 0
                            }
                        }
                )

                Spacer()

                // Page Indicators
                HStack(spacing: 12) {
                    ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        Circle()
                            .fill(currentIndex == index ? mode.color : Color.white.opacity(0.4))
                            .frame(
                                width: currentIndex == index ? 12 : 8,
                                height: currentIndex == index ? 12 : 8
                            )
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.bottom, 20)

                // Current Mode Label
                Text(GameMode.allCases[currentIndex].title)
                    .font(.custom("Candy-Planet", size: 24))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(GameMode.allCases[currentIndex].color.opacity(0.8))
                            .shadow(color: GameMode.allCases[currentIndex].color.opacity(0.5), radius: 10)
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)

                Spacer(minLength: 50)
            }
        }
        .navigationDestination(item: $selectedMode) { mode in
            destinationView(for: mode)
        }
    }

    // ✅ NEW helper (wrap around)
    private func wrappedIndex(_ i: Int, _ count: Int) -> Int {
        (i % count + count) % count
    }

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
    NavigationStack {
        ModeSelectionView()
    }
}
