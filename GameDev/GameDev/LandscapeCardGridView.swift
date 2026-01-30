//
//  Controls.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//


import SwiftUI

struct LandscapeCardGridView: View {

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let cardCount = 6

    let colorPool: [GameColor] = [
        GameColor(name: "Blue",     color: Color(red: 0.00, green: 0.45, blue: 0.70)),
        GameColor(name: "Orange",   color: Color(red: 0.90, green: 0.60, blue: 0.00)),
        GameColor(name: "Sky Blue", color: Color(red: 0.35, green: 0.70, blue: 0.90)),
        GameColor(name: "Bluish Green", color: Color(red: 0.00, green: 0.60, blue: 0.50)),
        GameColor(name: "Yellow",   color: Color(red: 0.95, green: 0.90, blue: 0.25)),
        GameColor(name: "Vermillion", color: Color(red: 0.80, green: 0.40, blue: 0.00)),
        GameColor(name: "Reddish Purple", color: Color(red: 0.80, green: 0.60, blue: 0.70)),
        GameColor(name: "Gray",     color: Color(red: 0.60, green: 0.60, blue: 0.60))
    ]

    @State private var selectedColors: [GameColor] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(selectedColors) { gameColor in
                    Button {
                        print("Tapped \(gameColor.name)")
                    } label: {
                        CardView(gameColor: gameColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Classic")
        .onAppear {
            pickColors()
        }
    }

    private func pickColors() {
        selectedColors = Array(colorPool.shuffled().prefix(cardCount))
    }
}
