//
//  ChaosModeView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/12/26.
//

import SwiftUI

struct ChaosModeView: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ChaosModeView_iPad(
                    currentScreen: $currentScreen,
                    engine: engine
                )
            } else {
                ChaosModeView_iPhone(
                    engine: engine, currentScreen: $currentScreen
                )
            }
        }
    }
}
