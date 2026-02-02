//
//  GameDevApp.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI
import GameKit

@main
struct GameDevApp: App {
    init() {
            authenticateGameCenter()
        }

        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }

        private func authenticateGameCenter() {
            GKLocalPlayer.local.authenticateHandler = { _, error in
                if let error = error {
                    print("Game Center auth error:", error.localizedDescription)
                } else {
                    print("\(GKLocalPlayer.local.alias) is ready to play!")
                }
            }
        }
}
