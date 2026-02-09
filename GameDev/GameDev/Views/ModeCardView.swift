//
//  ModeCardView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

struct ModeCardView: View {
    let mode: GameMode
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            
            // Title of the Mode
            Text(mode.title)
                //.font(.system(size: 28, weight: .heavy, design: .rounded))
                .font(.custom("Candy-Planet", size: 40))
                .foregroundColor(.black)
                .frame(height: 120)

            Divider()
            
            // Rules
            VStack(alignment: .leading, spacing: 8) {
                ForEach(mode.rules, id: \.self) { rule in
                    Text("• \(rule)")
                        .font(.system(size: 17))
                        .foregroundColor(.black.opacity(0.8))
                }
            }

            Spacer()
            
            // Start
            Button(action: onStart) {
                Text("START")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .frame(width: 300, height: 460)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(mode.color)
        )
        .shadow(radius: 10)
    }
}
