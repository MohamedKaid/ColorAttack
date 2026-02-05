//
//  GameKitManager.swift
//  GameDev
//
//  Created by Mohamed Kaid on 2/3/26.
//

import GameKit

enum GameCenterUI {
    static func showLeaderboards(authenticate: @escaping () -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }

        GKAccessPoint.shared.location = .topLeading
        GKAccessPoint.shared.isActive = true

        if GKAccessPoint.shared.isActive {
            GKAccessPoint.shared.trigger(state: .leaderboards, handler: {})
        }
    }
}
