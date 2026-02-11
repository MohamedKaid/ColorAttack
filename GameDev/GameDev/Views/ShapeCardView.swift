//
//  ShapeCardView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/2/26.
//

import SwiftUI

struct ShapeCardView: View {
    let shape: GameShape

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
            .overlay(
                Image(systemName: shape.symbol)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            )
            .frame(height: 100)
    }
}
