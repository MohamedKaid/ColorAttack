//
//  ClassicModeView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/12/26.
//

import SwiftUI

struct ClassicModeView: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ClassicModeView_iPad(
                    currentScreen: $currentScreen,
                    engine: engine
                )
            } else {
                ClassicModeView_iPhone(
                    currentScreen: $currentScreen,
                    engine: engine
                )
            }
        }
    }
}
