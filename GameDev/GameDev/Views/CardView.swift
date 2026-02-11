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
        RoundedRectangle(cornerRadius: 18)
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
                // Soft highlight (top-left light source)
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .blendMode(.overlay)
            )
            .overlay(
                // Subtle inner shadow for depth
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.25), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: 1, y: 2)
                    .mask(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .bottomTrailing,
                                    endPoint: .topLeading
                                )
                            )
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            .frame(height: 120)
            .overlay(
                Text(gameColor.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
            )
            .accessibilityLabel(gameColor.name)
    }
}

#Preview("3D Card") {
    CardView(
        gameColor: GameColor(name: "Blue", color: .blue)
    )
    .padding()
    .background(
        LinearGradient(
            colors: [.black, .gray.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}







