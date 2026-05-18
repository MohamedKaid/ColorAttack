//
//  GameDevApp.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI
import GameKit
import UserNotifications

@main
struct GameDevApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    GameCenterAuth.authenticate()
                    NotificationManager.shared.requestPermission()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        NotificationManager.shared.handleAppForeground()
                    }
                }
        }
    }
}
