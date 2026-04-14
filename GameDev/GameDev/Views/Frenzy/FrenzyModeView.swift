//
//  FrenzyModeView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid
//

import SwiftUI

struct FrenzyModeView: View {
    @Binding var currentScreen: AppScreen
    let colorPool: [GameColor]

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            FrenzyModeView_iPad(
                currentScreen: $currentScreen,
                colorPool: colorPool
            )
        } else {
            FrenzyModeView_iPhone(
                currentScreen: $currentScreen,
                colorPool: colorPool
            )
        }
    }
}
