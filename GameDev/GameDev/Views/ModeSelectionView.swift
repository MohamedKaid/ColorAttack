//
//  ModeSelectionView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var currentScreen: AppScreen
    @State private var currentIndex: Int = 0
    @State private var dragX: CGFloat = 0
    @State private var showSettings = false

    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 20

    // ✅ iPhone hides Chaos
    private var visibleModes: [GameMode] {
        UIDevice.current.userInterfaceIdiom == .phone
        ? GameMode.allCases.filter { $0 != .chaos }
        : GameMode.allCases
    }

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: .menu)
                .ignoresSafeArea()

            // Main content (blurred when settings shown)
            VStack {
                Spacer(minLength: 60)

                // Title
                Text("SELECT MODE")
                    .font(.custom("Candy-Planet", size: 32))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                Spacer(minLength: 40)

                // Carousel
                ZStack {
                    let modes = visibleModes
                    let count = modes.count
                    let sideOffset = cardWidth + cardSpacing

                    // Left card
                    ModeCardView(
                        mode: modes[wrappedIndex(currentIndex - 1, count)],
                        isSelected: false,
                        onStart: { navigateToMode(modes[wrappedIndex(currentIndex - 1, count)]) }
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
                        onStart: { navigateToMode(modes[wrappedIndex(currentIndex + 1, count)]) }
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
                        onStart: { navigateToMode(modes[currentIndex]) }
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
                                    currentIndex = wrappedIndex(currentIndex + 1, visibleModes.count)
                                }
                                generator.impactOccurred()
                            } else if predicted > threshold {
                                // swipe right -> prev
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentIndex = wrappedIndex(currentIndex - 1, visibleModes.count)
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
                    ForEach(Array(visibleModes.enumerated()), id: \.element.id) { index, mode in
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
                Text(visibleModes[currentIndex].title)
                    .font(.custom("Candy-Planet", size: 24))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(visibleModes[currentIndex].color.opacity(0.8))
                            .shadow(color: visibleModes[currentIndex].color.opacity(0.5), radius: 10)
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)

                Spacer(minLength: 50)
            }
            // ✅ Safety clamp (prevents crash on iPhone)
            .onAppear {
                currentIndex = min(currentIndex, visibleModes.count - 1)
            }
            .blur(radius: showSettings ? 8 : 0)
            .allowsHitTesting(!showSettings)

            // Settings popup overlay
            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }

        // Top bar — Back + Settings
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    currentScreen = .start
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.5))
        }
    }

    // Helper (wrap around)
    private func wrappedIndex(_ i: Int, _ count: Int) -> Int {
        (i % count + count) % count
    }

    private func navigateToMode(_ mode: GameMode) {
        // Extra safety: Chaos should never be reachable on iPhone
        if UIDevice.current.userInterfaceIdiom == .phone, mode == .chaos {
            return
        }

        switch mode {
        case .classic:
            currentScreen = .classic
        case .rapid:
            currentScreen = .rapid
        case .chaos:
            currentScreen = .chaos
        }
    }
}


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



#Preview("Mode Selection") {
    ModeSelectionView(currentScreen: .constant(.modeSelection))
}
