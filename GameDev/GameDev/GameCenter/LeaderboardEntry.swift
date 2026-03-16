//
//  LeaderboardEntry.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/18/26.
//

import Foundation

struct LeaderboardEntry: Identifiable, Equatable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let isLocalPlayer: Bool
}
