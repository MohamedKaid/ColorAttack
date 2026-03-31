//
//  ChaosInstructionView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 1/28/26.
//

import SwiftUI

struct ChaosInstructionView: View {
    let text: String

    var body: some View {
        let lines = text
            .split(separator: "\n")
            .map(String.init)

        VStack(spacing: 12) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.title2)
                    .foregroundColor(.white)
                    .bold()
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor(for: line))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private func backgroundColor(for line: String) -> Color {
        if line.contains("DON'T TAP") {
            return Color.red.opacity(0.35)
        } else {
            return Color.blue.opacity(0.35)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ChaosInstructionView(text: "TAP RED\nDON'T TAP CIRCLE")
    }
}
