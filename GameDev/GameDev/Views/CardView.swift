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
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .blendMode(.overlay)
            )
            .overlay(
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
            // ✅ Remove fixed height - let the grid control the size
            .overlay(
                Text(gameColor.name)
                    .font(.headline)
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
