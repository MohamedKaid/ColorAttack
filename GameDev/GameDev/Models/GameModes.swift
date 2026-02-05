//
//  GameModes.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//
import SwiftUI

enum GameMode: CaseIterable, Identifiable {
    case classic
    case rapid
    case chaos

    var id: Self { self }

    var title: String {
        switch self {
        case .classic: return "CLASSIC"
        case .rapid: return "RAPID"
        case .chaos: return "CHAOS"
        }
    }

    var color: Color {
        switch self {
        case .classic: return .yellow
        case .rapid: return .red
        case .chaos: return .blue
        }
    }

    var rules: [String] {
        switch self {
        case .classic:
            return [
                "Tap the instructed color",
                "Sometimes DON'T TAP",
                "Speed increases over time",
                "Game ends when lives run out"
            ]
        case .rapid:
            return [
                "Tap as fast as you can",
                "2 minute timer",
                "Wrong taps lose points",
                "No lives"
            ]
        case .chaos:
            return [
                "Colors + Shapes",
                "Two actions per round",
                "DON'T TAP rules",
                "Layouts may swap"
            ]
        }
    }
}
