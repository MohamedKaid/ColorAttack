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
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: shape.symbol)
                        .font(.system(size: geo.size.height * 0.38, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                )
        }
    }
}
