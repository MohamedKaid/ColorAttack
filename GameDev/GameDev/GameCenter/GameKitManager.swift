//
//  GameKitManager.swift
//  GameDev
//
//  Created by Mohamed Kaid on 2/3/26.
//

import SwiftUI
import GameKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class GameKitManager: NSObject {
    static let leaderboardID = "com.example.ColorAttack.Classic"
}
