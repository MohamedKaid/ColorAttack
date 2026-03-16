//
//  GameCenterLeaderboardService.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/18/26.
//

import Foundation
import GameKit

enum GameCenterLeaderboardService {

    static func loadTopEntries(
        leaderboardID: String,
        top: Int = 25
    ) async throws -> [LeaderboardEntry] {

        // Load the leaderboard object first
        let board = try await loadLeaderboard(id: leaderboardID)

        // Then load entries (global, all-time)
        let (localEntry, entries) = try await loadEntries(board: board, top: top)

        // Map to UI model
        let localPlayerID = GKLocalPlayer.local.gamePlayerID

        var mapped: [LeaderboardEntry] = entries.map { entry in
            let name = entry.player.displayName
            return LeaderboardEntry(
                id: entry.player.gamePlayerID,
                rank: entry.rank,
                displayName: name,
                score: entry.score,
                isLocalPlayer: entry.player.gamePlayerID == localPlayerID
            )
        }

        // If local player isn’t in top range, optionally prepend them (nice UX)
        if let local = localEntry {
            let alreadyInList = mapped.contains(where: { $0.id == local.player.gamePlayerID })
            if !alreadyInList {
                let localMapped = LeaderboardEntry(
                    id: local.player.gamePlayerID,
                    rank: local.rank,
                    displayName: local.player.displayName,
                    score: local.score,
                    isLocalPlayer: true
                )
                mapped.insert(localMapped, at: 0)
            }
        }

        return mapped
    }

    //Private Functions

    private static func loadLeaderboard(id: String) async throws -> GKLeaderboard {
        try await withCheckedThrowingContinuation { cont in
            GKLeaderboard.loadLeaderboards(IDs: [id]) { boards, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                if let board = boards?.first {
                    cont.resume(returning: board)
                } else {
                    cont.resume(throwing: NSError(
                        domain: "Leaderboard",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Leaderboard not found: \(id)"]
                    ))
                }
            }
        }
    }

    private static func loadEntries(
        board: GKLeaderboard,
        top: Int
    ) async throws -> (local: GKLeaderboard.Entry?, entries: [GKLeaderboard.Entry]) {
        try await withCheckedThrowingContinuation { cont in
            let range = NSRange(location: 1, length: max(1, top))
            board.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: range
            ) { localEntry, entries, _, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume(returning: (localEntry, entries ?? []))
            }
        }
    }
}
