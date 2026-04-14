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
    case frenzy

    var id: Self { self }

    var title: String {
        switch self {
        case .classic:  return "CLASSIC"
        case .rapid:    return "RAPID"
        case .chaos:    return "CHAOS"
        case .sequence: return "SEQUENCE"
        case .frenzy:   return "FRENZY"
        }
    }

    var leaderboardID: String {
        switch self {
        case .classic:  return "com.example.ColorAttack.Classic"
        case .rapid:    return "com.example.ColorAttack.Rapid"
        case .chaos:    return "com.example.ColorAttack.Chaos"
        case .sequence: return "com.example.ColorAttack.Sequence"
        case .frenzy:   return "com.example.ColorAttack.Frenzy"
        }
    }

    // Primary color — used for borders, play button, etc.
    // Frenzy uses red as its anchor color since rainbow gradient handles the header
    var color: Color {
        switch self {
        case .classic:  return Color(hex: "F4B400")
        case .rapid:    return Color(hex: "EA4335")
        case .chaos:    return Color(hex: "4285F4")
        case .sequence: return Color(hex: "34A853")
        case .frenzy:   return Color(hex: "FF3CAC")
        }
    }

    var colorSecondary: Color {
        switch self {
        case .classic:  return Color(hex: "F09819")
        case .rapid:    return Color(hex: "FF6B6B")
        case .chaos:    return Color(hex: "667EEA")
        case .sequence: return Color(hex: "00C9A7")
        case .frenzy:   return Color(hex: "784BA0")
        }
    }

    // Rainbow gradient colors for Frenzy header — nil for all other modes
    var rainbowColors: [Color]? {
        switch self {
        case .frenzy:
            return [
                Color(hex: "FF3CAC"),
                Color(hex: "FF6B35"),
                Color(hex: "FFD700"),
                Color(hex: "22C55E"),
                Color(hex: "00B4D8"),
                Color(hex: "784BA0")
            ]
        default:
            return nil
        }
    }

    var icon: String {
        switch self {
        case .classic:  return "star.fill"
        case .rapid:    return "bolt.fill"
        case .chaos:    return "tornado"
        case .sequence: return "list.number"
        case .frenzy:   return "flame.fill"
        }
    }

    var difficulty: String {
        switch self {
        case .classic:  return "BEGINNER"
        case .rapid:    return "INTERMEDIATE"
        case .chaos:    return "EXPERT"
        case .sequence: return "INTERMEDIATE"
        case .frenzy:   return "EXPERT"
        }
    }

    var difficultyColor: Color {
        switch self {
        case .classic:  return .green
        case .rapid:    return .orange
        case .chaos:    return .red
        case .sequence: return .orange
        case .frenzy:   return .red
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
        case .frenzy:
            return [
                "Cards are scattered and moving — tap the right color",
                "Cards speed up and multiply as you progress",
                "Timer runs out? You lose a life",
                "3 lives total — stay sharp and tap fast"
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
        case .frenzy:
            return ["hand.tap.fill", "speedometer", "timer", "heart.fill"]
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
