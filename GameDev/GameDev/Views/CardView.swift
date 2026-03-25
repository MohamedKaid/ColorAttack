//
//  CardView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

struct CardView: View {
    let gameColor: GameColor

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        gameColor.color.opacity(1.0),
                        gameColor.color.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Soft highlight
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .blendMode(.overlay)
            )
            .overlay(
                // Inner shadow
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.25), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: 1, y: 2)
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .bottomTrailing,
                                    endPoint: .topLeading
                                )
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .frame(height: 88) // HIG minimum touch target is 44pt, 88pt gives good spacing
            .overlay(
                Text(gameColor.name)
                    .font(.headline) // HIG semantic style - 17pt semibold
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 8)
            )
            .accessibilityLabel(gameColor.name)
            .accessibilityAddTraits(.isButton)
    }
}

#Preview("Card") {
    VStack(spacing: 16) {
        CardView(gameColor: GameColor(name: "Blue", color: .blue))
        CardView(gameColor: GameColor(name: "Red", color: .red))
        CardView(gameColor: GameColor(name: "Green", color: .green))
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.black, .gray.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
