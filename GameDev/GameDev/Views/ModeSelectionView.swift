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

    // Reduced card size for iPhone
    private let cardWidth: CGFloat = 240
    private let cardHeight: CGFloat = 380
    private let cardSpacing: CGFloat = 16

    // Hides Chaos on iPhone
    private var visibleModes: [GameMode] {
        UIDevice.current.userInterfaceIdiom == .phone
        ? GameMode.allCases.filter { mode in mode != .chaos }
        : GameMode.allCases
    }

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: .menu)
                .ignoresSafeArea()

            // Main Content
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Title
                Text("SELECT MODE")
                    .font(.custom("Candy-Planet", size: 26))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .padding(.top, 8)

                Spacer(minLength: 20)

                // Carousel
                ZStack {
                    let modes = visibleModes
                    let count = modes.count
                    let sideOffset = cardWidth + cardSpacing

                    // Left Card
                    ModeCardView(
                        mode: modes[wrappedIndex(currentIndex - 1, count)],
                        isSelected: false,
                        onStart: { navigateToMode(modes[wrappedIndex(currentIndex - 1, count)]) }
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(0.88)
                    .opacity(0.5)
                    .offset(x: -sideOffset + dragX * 0.35)
                    .allowsHitTesting(false)

                    // Right Card
                    ModeCardView(
                        mode: modes[wrappedIndex(currentIndex + 1, count)],
                        isSelected: false,
                        onStart: { navigateToMode(modes[wrappedIndex(currentIndex + 1, count)]) }
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(0.88)
                    .opacity(0.5)
                    .offset(x: sideOffset + dragX * 0.35)
                    .allowsHitTesting(false)

                    // Center Card
                    ModeCardView(
                        mode: modes[currentIndex],
                        isSelected: true,
                        onStart: { navigateToMode(modes[currentIndex]) }
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: dragX)
                }
                .frame(height: cardHeight + 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragX = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 70
                            let predicted = value.predictedEndTranslation.width
                            let generator = UIImpactFeedbackGenerator(style: .light)

                            if predicted < -threshold {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    currentIndex = wrappedIndex(currentIndex + 1, visibleModes.count)
                                }
                                generator.impactOccurred()
                            } else if predicted > threshold {
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

                Spacer(minLength: 16)

                // Page Indicators
                HStack(spacing: 10) {
                    ForEach(Array(visibleModes.enumerated()), id: \.element.id) { index, mode in
                        Circle()
                            .fill(currentIndex == index ? mode.color : Color.white.opacity(0.4))
                            .frame(
                                width: currentIndex == index ? 10 : 7,
                                height: currentIndex == index ? 10 : 7
                            )
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .padding(.bottom, 12)

                // Current Mode Label
                Text(visibleModes[currentIndex].title)
                    .font(.custom("Candy-Planet", size: 20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(visibleModes[currentIndex].color.opacity(0.8))
                            .shadow(color: visibleModes[currentIndex].color.opacity(0.5), radius: 8)
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)

                Spacer(minLength: 30)
            }
            .onAppear {
                currentIndex = min(currentIndex, visibleModes.count - 1)
            }
            .blur(radius: showSettings ? 8 : 0)
            .allowsHitTesting(!showSettings)

            // Settings Overlay
            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }

        // Top Bar
        .safeAreaInset(edge: .top) {
            HStack {
                // Back Button
                Button {
                    currentScreen = .start
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }

                Spacer()

                // Settings Button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(9)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.black.opacity(0.5))
        }
    }

    // MARK: - Helpers

    private func wrappedIndex(_ i: Int, _ count: Int) -> Int {
        (i % count + count) % count
    }

    private func navigateToMode(_ mode: GameMode) {
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

#Preview("Mode Selection") {
    ModeSelectionView(currentScreen: .constant(.modeSelection))
}
