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
    case sequence

    var id: Self { self }

    var title: String {
        switch self {
        case .classic:  return "CLASSIC"
        case .rapid:    return "RAPID"
        case .chaos:    return "CHAOS"
        case .sequence: return "SEQUENCE"
        }
    }

    var leaderboardID: String {
        switch self {
        case .classic:  return "com.example.ColorAttack.Classic"
        case .rapid:    return "com.example.ColorAttack.Rapid"
        case .chaos:    return "com.example.ColorAttack.Chaos"
        case .sequence: return "com.example.ColorAttack.Sequence"
        }
    }

    var color: Color {
        switch self {
        case .classic:  return Color(hex: "F4B400")
        case .rapid:    return Color(hex: "EA4335")
        case .chaos:    return Color(hex: "4285F4")
        case .sequence: return Color(hex: "34A853")
        }
    }

    var colorSecondary: Color {
        switch self {
        case .classic:  return Color(hex: "F09819")
        case .rapid:    return Color(hex: "FF6B6B")
        case .chaos:    return Color(hex: "667EEA")
        case .sequence: return Color(hex: "00C9A7")
        }
    }

    var icon: String {
        switch self {
        case .classic:  return "star.fill"
        case .rapid:    return "bolt.fill"
        case .chaos:    return "tornado"
        case .sequence: return "list.number"
        }
    }

    var difficulty: String {
        switch self {
        case .classic:  return "BEGINNER"
        case .rapid:    return "INTERMEDIATE"
        case .chaos:    return "EXPERT"
        case .sequence: return "INTERMEDIATE"
        }
    }

    var difficultyColor: Color {
        switch self {
        case .classic:  return .green
        case .rapid:    return .orange
        case .chaos:    return .red
        case .sequence: return .orange
        }
    }

    var rules: [String] {
        switch self {
        case .classic:
            return [
                "Match the color shown in the prompt",
                "DON'T TAP? Pick any other color",
                "Timer gets faster as you progress",
                "3 lives total — wrong tap loses one"
            ]
        case .rapid:
            return [
                "Tap every correct color as fast as you can",
                "You have 30 seconds — make them count",
                "Wrong taps deduct points",
                "Speed wins — but accuracy matters"
            ]
        case .chaos:
            return [
                "Match both a color AND a shape each round",
                "DON'T TAP? Pick any other option",
                "Tap both answers before the timer runs out",
                "Wrong taps cost a life",
                "Grid layout shifts randomly — stay sharp"
            ]
        case .sequence:
            return [
                "Watch the sequence carefully",
                "Tap colors and shapes in the exact order shown",
                "Wrong tap costs a life — but you stay on the same step",
                "Perfect round? Earn a bonus +15 points",
                "Sequence grows longer as you progress"
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
            return ["paintpalette.fill", "square.on.circle", "xmark.circle.fill", "speedometer", "arrow.triangle.swap"]
        case .sequence:
            return ["eye.fill", "hand.tap.fill", "heart.fill", "star.fill", "arrow.up.right"]
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
