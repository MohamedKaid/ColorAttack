//
//  GameBackground.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/8/26.
//
import SwiftUI

struct GameBackground: View {
    let mode: GameMode
    
    enum GameMode {
        case classic
        case rapid
        case chaos
        case menu
    }
    
    var body: some View {
        ZStack {
            // Base gradient
            baseGradient
            
            // Twinkling stars
            TwinklingStarsView()
            
            // Center glow
            RadialGradient(
                colors: [
                    accentGlow.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
        }
    }
    
    // Gradients
    @ViewBuilder
    private var baseGradient: some View {
        switch mode {
        case .menu:
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.12, blue: 0.35),
                    Color(red: 0.25, green: 0.18, blue: 0.55),
                    Color(red: 0.18, green: 0.12, blue: 0.42),
                    Color(red: 0.12, green: 0.10, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case .classic:
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.38),
                    Color(red: 0.20, green: 0.18, blue: 0.52),
                    Color(red: 0.16, green: 0.14, blue: 0.45),
                    Color(red: 0.10, green: 0.10, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case .rapid:
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.18, blue: 0.22),
                    Color(red: 0.55, green: 0.20, blue: 0.18),
                    Color(red: 0.40, green: 0.12, blue: 0.14),
                    Color(red: 0.18, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
        case .chaos:
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.10, blue: 0.40),
                    Color(red: 0.28, green: 0.15, blue: 0.58),
                    Color(red: 0.20, green: 0.10, blue: 0.48),
                    Color(red: 0.10, green: 0.06, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Accent for Center Glow
    private var accentGlow: Color {
        switch mode {
        case .menu:    return Color(red: 0.4, green: 0.3, blue: 0.8)
        case .classic: return Color(red: 0.3, green: 0.4, blue: 0.9)
        case .rapid:   return Color(red: 0.6, green: 0.25, blue: 0.2)
        case .chaos:   return Color(red: 0.4, green: 0.2, blue: 0.8)
        }
    }
}

// Twinkling Stars
private struct TwinklingStarsView: View {
    @State private var twinkle = false
    
    var body: some View {
        Canvas { context, size in
            
            // LAYER 1: Tiny background stars
            srand48(100)
            for _ in 0..<300 {
                let x = drand48() * size.width
                let y = drand48() * size.height
                let starSize = drand48() * 1.2 + 0.3  // Very small: 0.3 - 1.5
                let opacity = drand48() * 0.4 + 0.1   // Dim: 0.1 - 0.5
                
                let rect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )
                
                context.opacity = opacity
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
            
            // === LAYER 2: Medium stars ===
            srand48(200)
            for i in 0..<80 {
                let x = drand48() * size.width
                let y = drand48() * size.height
                let baseSize = drand48() * 2.5 + 1.5  // Little Bigger: 1.5 - 4
                let baseOpacity = drand48() * 0.4 + 0.5  // Brighter: 0.5 - 0.9
                
                // 1/4 will twinkle(get brighter/bigger)
                let shouldTwinkle = i % 4 == 0
                let opacity = shouldTwinkle && twinkle
                    ? min(baseOpacity * 1.4, 1.0)
                    : baseOpacity
                
                let starSize = shouldTwinkle && twinkle
                    ? baseSize * 1.3
                    : baseSize
                
                let rect = CGRect(
                    x: x - starSize / 2,
                    y: y - starSize / 2,
                    width: starSize,
                    height: starSize
                )
                
                context.opacity = opacity
                context.fill(Path(ellipseIn: rect), with: .color(.white))
            }
            
            // === LAYER 3: Bright stars with glows ===
            srand48(300)
            for i in 0..<15 {
                let x = drand48() * size.width
                let y = drand48() * size.height
                let center = CGPoint(x: x, y: y)
                
                // Star color (some white, some tinted)
                let colors: [Color] = [.white, .white, .white, .cyan, .orange, .yellow]
                let starColor = colors[i % colors.count]
                
                // Glow size pulses
                let glowSize = twinkle ? 35.0 : 20.0
                let glowOpacity = twinkle ? 0.6 : 0.3
                
                // Draw outer glow
                let glowRect = CGRect(
                    x: center.x - glowSize / 2,
                    y: center.y - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                )
                
                context.opacity = glowOpacity
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            starColor,
                            starColor.opacity(0.4),
                            starColor.opacity(0.1),
                            .clear
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: glowSize / 2
                    )
                )
                
                // Draw bright core
                let coreSize = twinkle ? 6.0 : 4.0
                let coreRect = CGRect(
                    x: center.x - coreSize / 2,
                    y: center.y - coreSize / 2,
                    width: coreSize,
                    height: coreSize
                )
                
                context.opacity = 1.0
                context.fill(Path(ellipseIn: coreRect), with: .color(starColor))
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                twinkle = true
            }
        }
    }
}

// MARK: - Previews

#Preview("All Modes") {
    TabView {
        GameBackground(mode: .menu)
            .ignoresSafeArea()
            .overlay(Text("MENU").font(.largeTitle).bold().foregroundColor(.white))
            .tabItem { Text("Menu") }
        
        GameBackground(mode: .classic)
            .ignoresSafeArea()
            .overlay(Text("CLASSIC").font(.largeTitle).bold().foregroundColor(.white))
            .tabItem { Text("Classic") }
        
        GameBackground(mode: .rapid)
            .ignoresSafeArea()
            .overlay(Text("RAPID").font(.largeTitle).bold().foregroundColor(.white))
            .tabItem { Text("Rapid") }
        
        GameBackground(mode: .chaos)
            .ignoresSafeArea()
            .overlay(Text("CHAOS").font(.largeTitle).bold().foregroundColor(.white))
            .tabItem { Text("Chaos") }
    }
}
