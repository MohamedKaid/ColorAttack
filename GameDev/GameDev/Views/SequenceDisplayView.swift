//
//  SequenceDisplayView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 3/30/26.
//

import SwiftUI

struct SequenceDisplayView: View {
    let sequence: [SequenceItem]
    let onComplete: () -> Void

    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    private let displayDuration: TimeInterval = 0.8
    private let gapDuration: TimeInterval = 0.3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()

                VStack(spacing: h * 0.03) {

                    Text("MEMORIZE")
                        .font(.system(size: w * 0.045, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(4)

                    // Progress dots
                    HStack(spacing: w * 0.02) {
                        ForEach(0..<sequence.count, id: \.self) { i in
                            Circle()
                                .fill(i < currentIndex ? Color.green : Color.white.opacity(0.3))
                                .frame(
                                    width: i == currentIndex ? w * 0.028 : w * 0.02,
                                    height: i == currentIndex ? w * 0.028 : w * 0.02
                                )
                                .animation(.spring(response: 0.3), value: currentIndex)
                        }
                    }

                    // Current item
                    if currentIndex < sequence.count {
                        currentItemView(sequence[currentIndex], w: w)
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }

                    Text("\(currentIndex + 1) of \(sequence.count)")
                        .font(.system(size: w * 0.038, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, w * 0.08)
            }
        }
        .onAppear {
            showNext()
        }
    }

    // MARK: - Item View

    @ViewBuilder
    private func currentItemView(_ item: SequenceItem, w: CGFloat) -> some View {
        let cardW = w * 0.52
        let cardH = cardW * 0.65
        let cornerR = w * 0.05

        switch item {
        case .color(let gameColor):
            RoundedRectangle(cornerRadius: cornerR)
                .fill(
                    LinearGradient(
                        colors: [gameColor.color, gameColor.color.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerR)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    Text(gameColor.name.uppercased())
                        .font(.system(size: w * 0.07, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .padding(.horizontal, w * 0.04)
                )
                .frame(width: cardW, height: cardH)
                .shadow(color: gameColor.color.opacity(0.6), radius: w * 0.05)

        case .shape(let gameShape):
            RoundedRectangle(cornerRadius: cornerR)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerR)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    VStack(spacing: w * 0.02) {
                        Image(systemName: gameShape.symbol)
                            .font(.system(size: w * 0.13, weight: .bold))
                            .foregroundColor(.white)
                        Text(gameShape.rawValue.uppercased())
                            .font(.system(size: w * 0.042, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
                .frame(width: cardW, height: cardH)
                .shadow(color: Color.white.opacity(0.2), radius: w * 0.05)
        }
    }

    // MARK: - Animation

    private func showNext() {
        guard currentIndex < sequence.count else {
            onComplete()
            return
        }

        scale = 0.5
        opacity = 0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            scale = 1.0
            opacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 1.2
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + gapDuration) {
                currentIndex += 1
                if currentIndex < sequence.count {
                    showNext()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SequenceDisplayView(
        sequence: [
            .color(GameColor(name: "Red", color: Color(hex: "E64040"))),
            .shape(.circle),
            .color(GameColor(name: "Blue", color: Color(hex: "4080F2"))),
            .shape(.star),
            .color(GameColor(name: "Green", color: Color(hex: "4DBF66")))
        ],
        onComplete: { print("Done!") }
    )
}
