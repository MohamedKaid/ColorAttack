//
//  SequenceModeView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 3/30/26.
//
import SwiftUI

struct SequenceModeView: View {
    @Binding var currentScreen: AppScreen
    @StateObject var engine: GameEngine

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                SequenceModeView_iPad(
                    currentScreen: $currentScreen,
                    engine: engine
                )
            } else {
                SequenceModeView_iPhone(
                    currentScreen: $currentScreen,
                    engine: engine
                )
            }
        }
    }
}
