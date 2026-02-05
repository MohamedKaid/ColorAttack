//
//  Luminance.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

extension Color {
    var luminance: Double {
        #if os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        let r = nsColor.redComponent
        let g = nsColor.greenComponent
        let b = nsColor.blueComponent
        #endif

        // Standard WCAG luminance formula
        return 0.2126 * Double(r) +
               0.7152 * Double(g) +
               0.0722 * Double(b)
    }

    var isLight: Bool {
        luminance > 0.6
    }
}
