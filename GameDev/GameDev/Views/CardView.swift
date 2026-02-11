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
            .fill(gameColor.color)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.35), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            .frame(height: 120)
            .overlay(
                Text(gameColor.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            )
            .accessibilityLabel(gameColor.name)
            .shadow(radius: 6)
    }
}






