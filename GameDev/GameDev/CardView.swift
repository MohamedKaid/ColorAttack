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
            .frame(height: 150)
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




