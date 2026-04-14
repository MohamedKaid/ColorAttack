//
//  FrenzyRules.swift
//  GameDev
//

import SwiftUI

struct FrenzyLevel {
    let cardCount: Int
    let speed: CGFloat        // points per frame
    let tapTimeLimit: Double  // seconds before life lost
}

final class FrenzyRules {

    // Level thresholds by score
    static let levels: [FrenzyLevel] = [
        FrenzyLevel(cardCount: 4, speed: 0.8,  tapTimeLimit: 4.0),  // Level 1: 0–29
        FrenzyLevel(cardCount: 5, speed: 1.1,  tapTimeLimit: 3.5),  // Level 2: 30–59
        FrenzyLevel(cardCount: 6, speed: 1.4,  tapTimeLimit: 3.0),  // Level 3: 60–99
        FrenzyLevel(cardCount: 7, speed: 1.7,  tapTimeLimit: 2.5),  // Level 4: 100–149
        FrenzyLevel(cardCount: 8, speed: 2.0,  tapTimeLimit: 2.0),  // Level 5: 150+
    ]

    static func level(for score: Int) -> FrenzyLevel {
        switch score {
        case 0..<30:   return levels[0]
        case 30..<60:  return levels[1]
        case 60..<100: return levels[2]
        case 100..<150: return levels[3]
        default:       return levels[4]
        }
    }

    static func levelNumber(for score: Int) -> Int {
        switch score {
        case 0..<30:   return 1
        case 30..<60:  return 2
        case 60..<100: return 3
        case 100..<150: return 4
        default:       return 5
        }
    }

    // Points awarded per correct tap
    static let pointsPerTap = 10

    // Bumped up from 60 for better tappability and readability
    static let minCardSize: CGFloat = 80
}
