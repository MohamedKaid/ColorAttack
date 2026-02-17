//
//  LeaderboardStats.swift
//  GameDev
//
//  Created by Mohamed Kaid on 2/5/26.
//


import GameKit

func loadMyBestScore(leaderboardID: String, completion: @escaping (Int) -> Void) {
    guard GKLocalPlayer.local.isAuthenticated else {
        GameCenterAuth.authenticate {
            loadMyBestScore(leaderboardID: leaderboardID, completion: completion)
        }
        return
    }

    GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { boards, error in
        if let error {
            print("loadLeaderboards error:", error.localizedDescription)
            DispatchQueue.main.async { completion(0) }
            return
        }

        guard let leaderboard = boards?.first else {
            print("No leaderboard found for ID:", leaderboardID)
            DispatchQueue.main.async { completion(0) }
            return
        }

        leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1)) {
            localEntry, _, _, error in

            if let error {
                print("loadEntries error:", error.localizedDescription)
                DispatchQueue.main.async { completion(0) }
                return
            }

            DispatchQueue.main.async { completion(localEntry?.score ?? 0) }
        }
    }
}
