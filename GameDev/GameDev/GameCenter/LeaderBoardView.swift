//
//  LeaderBoardView.swift
//  Color Frenzy
//
//  Created by Mohamed Kaid on 2/18/26.
//

import SwiftUI
import GameKit

struct LeaderBoardView: View {
    let leaderboardID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GameCenterLeaderboardController(leaderboardID: leaderboardID) {
            dismiss()
        }
        .ignoresSafeArea()
    }
}

struct GameCenterLeaderboardController: UIViewControllerRepresentable {
    let leaderboardID: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.leaderboardIdentifier = leaderboardID
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            onFinish()
        }
    }
}
