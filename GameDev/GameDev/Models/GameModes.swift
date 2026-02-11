//
//  GameModes.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//
//import SwiftUI
//
//enum GameMode: CaseIterable, Identifiable {
//    case classic
//    case rapid
//    case chaos
//
//    var id: Self { self }
//
//    var title: String {
//        switch self {
//        case .classic: return "CLASSIC"
//        case .rapid: return "RAPID"
//        case .chaos: return "CHAOS"
//        }
//    }
//
//    var color: Color {
//        switch self {
//        case .classic: return .yellow
//        case .rapid: return .red
//        case .chaos: return .blue
//        }
//    }
//    
//    var colorSecondary: Color {
//            switch self {
//            case .classic: return Color(hex: "F09819") // Orange
//            case .rapid: return Color(hex: "FF6B6B") // Lighter red
//            case .chaos: return Color(hex: "667EEA") // Purple-blue
//            }
//        }
//
//    var rules: [String] {
//        switch self {
//        case .classic:
//            return [
//                "Tap the instructed color",
//                "Sometimes DON'T TAP",
//                "Speed increases over time",
//                "Game ends when lives run out"
//            ]
//        case .rapid:
//            return [
//                "Tap as fast as you can",
//                "2 minute timer",
//                "Wrong taps lose points",
//                "No lives"
//            ]
//        case .chaos:
//            return [
//                "Colors + Shapes",
//                "Two actions per round",
//                "DON'T TAP rules",
//                "Layouts may swap"
//            ]
//        }
//    }
//}
//
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue: Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}
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
        case .classic: return Color(hex: "F4B400") // Golden yellow
        case .rapid: return Color(hex: "EA4335") // Vibrant red
        case .chaos: return Color(hex: "4285F4") // Blue
        }
    }
    
    var colorSecondary: Color {
        switch self {
        case .classic: return Color(hex: "F09819") // Orange
        case .rapid: return Color(hex: "FF6B6B") // Lighter red
        case .chaos: return Color(hex: "667EEA") // Purple-blue
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "star.fill"
        case .rapid: return "bolt.fill"
        case .chaos: return "tornado"
        }
    }
    
    var difficulty: String {
        switch self {
        case .classic: return "BEGINNER"
        case .rapid: return "INTERMEDIATE"
        case .chaos: return "EXPERT"
        }
    }
    
    var difficultyColor: Color {
        switch self {
        case .classic: return .green
        case .rapid: return .orange
        case .chaos: return .red
        }
    }

    var rules: [String] {
        switch self {
        case .classic:
            return [
                "Tap: Select the color shown",
                "Don’t Tap: Tap any color except the one shown",
                "Speed increases over time",
                "Game ends when lives run out"
            ]
        case .rapid:
            return [
                "Tap as fast as you can",
                "2 minute timer",
                "Wrong taps lose points",
                "No lives - just speed!"
            ]
        case .chaos:
            return [
                "Colors + Shapes combined",
                "Two actions per round",
                "DON'T TAP rules apply",
                "Layouts may swap randomly"
            ]
        }
    }
    
    var ruleIcons: [String] {
        switch self {
        case .classic:
            return ["hand.tap.fill", "xmark.circle.fill", "speedometer", "heart.fill"]
        case .rapid:
            return ["hand.tap.fill", "timer", "minus.circle.fill", "flame.fill"]
        case .chaos:
            return ["paintpalette.fill", "square.on.circle", "xmark.circle.fill", "arrow.triangle.swap"]
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
