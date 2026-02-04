//
//  GameCenterAuth.swift
//  GameDev
//
//  Created by Mohamed Kaid on 2/4/26.
//

import GameKit
import UIKit

enum GameCenterAuth {
    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController {
                UIApplication.shared.topMostViewController?.present(viewController, animated: true)
                return
            }

            if let error {
                print("Game Center auth error:", error.localizedDescription)
                return
            }

            if GKLocalPlayer.local.isAuthenticated {
                print("\(GKLocalPlayer.local.alias) is ready to play!")
            } else {
                print("Game Center not authenticated.")
            }
        }
    }
}

private extension UIApplication {
    var topMostViewController: UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
