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
            .fill(Color.secondary.opacity(0.15))
            .overlay(
                Image(systemName: shape.symbol)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
            )
            .frame(height: 120)
    }
}
