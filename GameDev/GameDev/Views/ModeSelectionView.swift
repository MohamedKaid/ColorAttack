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

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var visibleModes: [GameMode] {
        GameMode.allCases
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // On iPad landscape the card should be height-constrained
            // On iPhone it stays width-constrained like before
            let cardHeight: CGFloat = isIPad
                ? h * 0.60
                : h * 0.50

            let cardWidth: CGFloat = isIPad
                ? min(cardHeight * 0.72, w * 0.38)
                : w * 0.62

            let cardSpacing: CGFloat = isIPad
                ? w * 0.025
                : w * 0.04

            ZStack {
                GameBackground(mode: .menu)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: h * 0.03)

                    // Title
                    Text("SELECT MODE")
                        .font(.custom("Candy-Planet", size: isIPad ? h * 0.08 : w * 0.07))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .padding(.top, h * 0.01)
                        .accessibilityAddTraits(.isHeader)

                    Spacer(minLength: h * 0.03)

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
                        .accessibilityHidden(true)

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
                        .accessibilityHidden(true)

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

                    Spacer(minLength: h * 0.02)

                    // Page Indicators
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
                    .padding(.bottom, h * 0.015)
                    .accessibilityHidden(true)

                    // Mode Label
                    Text(visibleModes[currentIndex].title)
                        .font(.title3)
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
                        .accessibilityHidden(true)

                    Spacer(minLength: h * 0.04)
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
        }
        // Top Bar
        .safeAreaInset(edge: .top) {
            HStack {
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
                    .frame(minHeight: 44)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(12)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
        }
    }

    // MARK: - Helpers

    private func wrappedIndex(_ i: Int, _ count: Int) -> Int {
        (i % count + count) % count
    }

    private func navigateToMode(_ mode: GameMode) {
        switch mode {
        case .classic:
            currentScreen = .classic
        case .rapid:
            currentScreen = .rapid
        case .chaos:
            currentScreen = .chaos
        case .sequence:
            currentScreen = .sequence
        case .frenzy:
            currentScreen = .frenzy
        }
    }
}
