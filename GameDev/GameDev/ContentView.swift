//
//  ContentView.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI

let colorPool: [GameColor] = [
    // Saturated, distinct colors that pop on dark backgrounds
    GameColor(name: "Red",    color: Color(red: 0.90, green: 0.25, blue: 0.25)),
    GameColor(name: "Blue",   color: Color(red: 0.25, green: 0.50, blue: 0.95)),
    GameColor(name: "Yellow", color: Color(red: 0.80, green: 0.68, blue: 0.00)),
    GameColor(name: "Green",  color: Color(red: 0.30, green: 0.75, blue: 0.40)),
    GameColor(name: "Orange", color: Color(red: 0.95, green: 0.55, blue: 0.20)),
    GameColor(name: "Purple", color: Color(red: 0.65, green: 0.40, blue: 0.85)),
    GameColor(name: "Brown",  color: Color(red: 0.60, green: 0.40, blue: 0.25)),
    GameColor(name: "Black",  color: Color(red: 0.15, green: 0.15, blue: 0.18)),
    GameColor(name: "Pink",   color: Color(red: 0.95, green: 0.45, blue: 0.60))
]
struct ContentView: View {
    var body: some View {
        NavigationStack {
            StartView()
        }
        .onAppear {
            GameCenterAuth.authenticate()
        }
    }
}

#Preview {
    ContentView()
}
