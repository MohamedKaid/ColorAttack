//
//  Lives.swift
//  GameDev
//
//  Created by Mohamed Kaid on 1/27/26.
//

import SwiftUI
import Combine

@MainActor
final class Lives: ObservableObject {

    @Published private(set) var current: Int
    let max: Int

    init(max: Int) {
        self.max = max
        self.current = max
    }

    func lose() {
        guard current > 0 else { return }
        current -= 1
    }

    func reset() {
        current = max
    }

    func setMax(_ newMax: Int) {
        current = newMax
    }

    var isEmpty: Bool {
        current == 0
    }
}

