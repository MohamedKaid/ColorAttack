//
//  Luminance.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

// Used for determining the background of the prompts to ensure color contrast
extension Color {
    var luminance: Double {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return 0.2126 * Double(r) +
               0.7152 * Double(g) +
               0.0722 * Double(b)
    }

    var isLight: Bool {
        luminance > 0.6
    }
}
