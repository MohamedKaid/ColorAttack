//
//  FrenzyCardView.swift
//  GameDev
//

import SwiftUI

struct FrenzyCardView: View {
    let gameColor: GameColor

    // Use dark text for light colors, white for dark colors
    private var textColor: Color {
        gameColor.color.isLight ? Color.black.opacity(0.75) : .white
    }

    // Dark cards need a stronger visible border to stand out from the background
    private var borderColor: Color {
        gameColor.color.isLight
            ? Color.white.opacity(0.3)
            : Color.white.opacity(0.6)
    }

    private var borderWidth: CGFloat {
        gameColor.color.isLight ? 1.5 : 2.5
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(gameColor.color)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .overlay(
                Text(gameColor.name.uppercased())
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(textColor)
                    .shadow(
                        color: gameColor.color.isLight
                            ? Color.white.opacity(0.4)
                            : Color.black.opacity(0.8),
                        radius: 3,
                        x: 0,
                        y: 1
                    )
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            )
            .accessibilityLabel(gameColor.name)
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack(spacing: 12) {
        FrenzyCardView(gameColor: GameColor(name: "Red", color: Color(hex: "E64040")))
            .frame(width: 76, height: 76)
        FrenzyCardView(gameColor: GameColor(name: "Yellow", color: Color(hex: "CCAD00")))
            .frame(width: 76, height: 76)
        FrenzyCardView(gameColor: GameColor(name: "Black", color: Color(hex: "26262E")))
            .frame(width: 76, height: 76)
        FrenzyCardView(gameColor: GameColor(name: "White", color: Color(hex: "F0F0F0")))
            .frame(width: 76, height: 76)
    }
    .padding()
    .background(Color.black)
}
