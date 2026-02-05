//
//  LeaderboardStats.swift
//  GameDev
//
//  Created by Mohamed Kaid on 2/5/26.
//

import GameKit

func loadMyBestScore(
    leaderboardID: String,
    completion: @escaping (Int) -> Void
) {
    GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { boards, _ in
        guard let leaderboard = boards?.first else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }

        leaderboard.loadEntries(
            for: .global,
            timeScope: .allTime,
            range: NSRange(location: 1, length: 1)
        ) { localEntry, _, _, _ in
            let score = localEntry?.score ?? 0
            DispatchQueue.main.async {
                completion(score)
            }
        }
    }
}



