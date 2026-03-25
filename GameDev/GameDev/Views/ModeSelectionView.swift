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

    private let cardWidth: CGFloat = 220
    private let cardHeight: CGFloat = 340
    private let cardSpacing: CGFloat = 16

    // AFTER — clean
    private var visibleModes: [GameMode] {
        GameMode.allCases
    }

    var body: some View {
        ZStack {
            GameBackground(mode: .menu)
                .ignoresSafeArea()

            // Main Content
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                // Title
                // HIG - Large Title 34pt for screen headers
                Text("SELECT MODE")
                    .font(.custom("Candy-Planet", size: 28))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 24)

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
                    .accessibilityHidden(true) // HIG - hide non-focused carousel items

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
                    .accessibilityHidden(true) // HIG - hide non-focused carousel items

                    // Center Card
                    ModeCardView(
                        mode: modes[currentIndex],
                        isSelected: true,
                        onStart: { navigateToMode(modes[currentIndex]) }
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: dragX)
                    .accessibilityLabel("\(modes[currentIndex].title) mode, selected")
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
                            // HIG - use haptics for meaningful interactions 
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
                // HIG - accessibility actions for swipe carousel
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(visibleModes[currentIndex].title)
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        withAnimation {
                            currentIndex = wrappedIndex(currentIndex + 1, visibleModes.count)
                        }
                    case .decrement:
                        withAnimation {
                            currentIndex = wrappedIndex(currentIndex - 1, visibleModes.count)
                        }
                    @unknown default:
                        break
                    }
                }

                Spacer(minLength: 16)

                // Page Indicators
                // HIG - use clear visual indicators for pagination
                HStack(spacing: 8) {
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
                .accessibilityHidden(true) // decorative only

                // Mode Label
                Text(visibleModes[currentIndex].title)
                    .font(.title3) // HIG - 20pt
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(visibleModes[currentIndex].color.opacity(0.8))
                            .shadow(
                                color: visibleModes[currentIndex].color.opacity(0.5),
                                radius: 8
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    .accessibilityHidden(true) // already announced by carousel

                Spacer(minLength: 32)
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
                // HIG - back buttons should be clear and use chevron.left
                Button {
                    currentScreen = .start
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .accessibilityHidden(true)
                        Text("Back")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    // HIG - minimum touch target 44x44pt
                    .frame(minHeight: 44)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .accessibilityLabel("Back")

                Spacer()

                // HIG - settings icon should be gearshape
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body) // HIG - body size for toolbar icons
                        .foregroundColor(.white.opacity(0.9))
                        .padding(12)
                        // HIG - minimum touch target 44x44pt
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16) // HIG standard margin
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
        }
    }

    // MARK: - Helpers

    private func wrappedIndex(_ i: Int, _ count: Int) -> Int {
        (i % count + count) % count
    }

    //this is to turn off chaos mode in iPhone//
    
//    private func navigateToMode(_ mode: GameMode) {
//        if UIDevice.current.userInterfaceIdiom == .phone, mode == .chaos {
//            return
//        }
//        switch mode {
//        case .classic:
//            currentScreen = .classic
//        case .rapid:
//            currentScreen = .rapid
//        case .chaos:
//            currentScreen = .chaos
//        }
//    }
    
    // all modes work
    private func navigateToMode(_ mode: GameMode) {
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
