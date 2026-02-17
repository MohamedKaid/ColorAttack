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
    // Multiple twinkle states at different speeds
    @State private var twinkleFast = false
    @State private var twinkleMedium = false
    @State private var twinkleSlow = false
    
    // Movement states
    @State private var driftX = false
    @State private var driftY = false
    @State private var float = false
    
    // Shooting stars
    @State private var shootingStar1Active = false
    @State private var shootingStar1Offset: CGFloat = -300
    @State private var shootingStar2Active = false
    @State private var shootingStar2Offset: CGFloat = -300
    @State private var shootingStar3Active = false
    @State private var shootingStar3Offset: CGFloat = -300
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                
                // Layer 1: Tiny background stars
                srand48(100)
                for i in 0..<350 {
                    var x = drand48() * size.width
                    var y = drand48() * size.height
                    let baseSize = drand48() * 1.4 + 0.3
                    let baseOpacity = drand48() * 0.5 + 0.15
                    
                    // Movement for the stars
                    let movePattern = i % 4
                    switch movePattern {
                    case 0:
                        x += driftX ? 25 : -25
                    case 1:
                        y += driftY ? 20 : -20
                    case 2:
                        x += float ? -18 : 18
                        y += float ? 15 : -15
                    default:
                        break // Some stay still for contrast
                    }
                    
                    let shouldTwinkle = i % 4 == 0
                    let whichTwinkle = i % 3
                    let isTwinkling: Bool
                    switch whichTwinkle {
                    case 0: isTwinkling = twinkleFast
                    case 1: isTwinkling = twinkleMedium
                    default: isTwinkling = twinkleSlow
                    }
                    
                    let opacity = shouldTwinkle && isTwinkling
                        ? min(baseOpacity * 3.0, 1.0)
                        : shouldTwinkle && !isTwinkling
                            ? baseOpacity * 0.3
                            : baseOpacity
                    
                    let starSize = shouldTwinkle && isTwinkling
                        ? baseSize * 2.2
                        : baseSize
                    
                    // Star Struct
                    let rect = CGRect(
                        x: x - starSize / 2,
                        y: y - starSize / 2,
                        width: starSize,
                        height: starSize
                    )
                    
                    context.opacity = opacity
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
                
                // Layer 2: Medium Sized Stars with more movement and twinkle
                srand48(200)
                for i in 0..<120 {
                    var x = drand48() * size.width
                    var y = drand48() * size.height
                    let baseSize = drand48() * 3.0 + 1.5
                    let baseOpacity = drand48() * 0.4 + 0.5
                    
                    // Stars have a larger range than previous layer
                    let movePattern = i % 5
                    switch movePattern {
                    case 0:
                        x += driftX ? 45 : -45
                        y += driftY ? 20 : -20
                    case 1:
                        y += driftY ? 50 : -50
                        x += driftX ? -15 : 15
                    case 2:
                        x += float ? 40 : -40
                        y += float ? -35 : 35
                    case 3:
                        x += driftX ? -50 : 50
                        y += float ? 25 : -25
                    default:
                        x += float ? 30 : -30
                        y += driftY ? -40 : 40
                    }
                    
                    let twinkleGroup = i % 3
                    let isTwinkling: Bool
                    switch twinkleGroup {
                    case 0: isTwinkling = twinkleFast
                    case 1: isTwinkling = twinkleMedium
                    default: isTwinkling = twinkleSlow
                    }
                    
                    let shouldTwinkle = i % 2 == 0
                    let opacity = shouldTwinkle && isTwinkling
                        ? min(baseOpacity * 1.8, 1.0)
                        : shouldTwinkle && !isTwinkling
                            ? baseOpacity * 0.4
                            : baseOpacity
                    
                    let starSize = shouldTwinkle && isTwinkling
                        ? baseSize * 1.6
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
                
                // Layer 3: Bright Glowing Stars
                srand48(300)
                for i in 0..<25 {
                    var x = drand48() * size.width
                    var y = drand48() * size.height
                    
                    // ALL bright stars move A LOT
                    let movePattern = i % 6
                    switch movePattern {
                    case 0:
                        x += driftX ? 70 : -70
                        y += driftY ? 40 : -40
                    case 1:
                        x += float ? -60 : 60
                        y += float ? 55 : -55
                    case 2:
                        x += driftX ? 50 : -50
                        y += float ? -60 : 60
                    case 3:
                        y += driftY ? 75 : -75
                        x += float ? 30 : -30
                    case 4:
                        x += driftX ? -65 : 65
                        y += driftY ? -45 : 45
                    default:
                        x += float ? 55 : -55
                        y += driftX ? 50 : -50
                    }
                    
                    let center = CGPoint(x: x, y: y)
                    
                    // Mostly white, subtle colors
                    let colors: [Color] = [
                        .white, .white, .white, .white, .white,
                        .cyan.opacity(0.7),
                        .orange.opacity(0.6),
                        .yellow.opacity(0.6)
                    ]
                    let starColor = colors[i % colors.count]
                    
                    let twinkleType = i % 3
                    let isTwinkling: Bool
                    switch twinkleType {
                    case 0: isTwinkling = twinkleFast
                    case 1: isTwinkling = twinkleMedium
                    default: isTwinkling = twinkleSlow
                    }
                    
                    let glowSize = isTwinkling ? 40.0 : 12.0
                    let glowOpacity = isTwinkling ? 0.5 : 0.12
                    
                    // Outer glow
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
                                starColor.opacity(0.8),
                                starColor.opacity(0.4),
                                starColor.opacity(0.1),
                                .clear
                            ]),
                            center: center,
                            startRadius: 0,
                            endRadius: glowSize / 2
                        )
                    )
                    
                    // Second glow layer
                    if isTwinkling {
                        let outerGlowSize = glowSize * 1.3
                        let outerGlowRect = CGRect(
                            x: center.x - outerGlowSize / 2,
                            y: center.y - outerGlowSize / 2,
                            width: outerGlowSize,
                            height: outerGlowSize
                        )
                        
                        context.opacity = 0.15
                        context.fill(
                            Path(ellipseIn: outerGlowRect),
                            with: .radialGradient(
                                Gradient(colors: [
                                    starColor.opacity(0.3),
                                    .clear
                                ]),
                                center: center,
                                startRadius: 0,
                                endRadius: outerGlowSize / 2
                            )
                        )
                    }
                    
                    // Bright core
                    let coreSize = isTwinkling ? 7.0 : 2.5
                    let coreRect = CGRect(
                        x: center.x - coreSize / 2,
                        y: center.y - coreSize / 2,
                        width: coreSize,
                        height: coreSize
                    )
                    
                    context.opacity = 1.0
                    context.fill(Path(ellipseIn: coreRect), with: .color(.white))
                }
            }
            
            //  Shooting Stars
            if shootingStar1Active {
                ShootingStarView(color: .white)
                    .rotationEffect(.degrees(40))
                    .offset(
                        x: shootingStar1Offset,
                        y: shootingStar1Offset * 0.6
                    )
            }
            
            if shootingStar2Active {
                ShootingStarView(color: .white.opacity(0.9))
                    .rotationEffect(.degrees(140))
                    .offset(
                        x: -shootingStar2Offset,
                        y: shootingStar2Offset * 0.5
                    )
            }
            
            if shootingStar3Active {
                ShootingStarView(color: .white.opacity(0.8))
                    .rotationEffect(.degrees(20))
                    .offset(
                        x: shootingStar3Offset,
                        y: shootingStar3Offset * 0.2 + 100
                    )
            }
        }
        .onAppear {
            startAnimations()
            startShootingStars()
        }
    }
    
    private func startAnimations() {
        // Fast twinkle
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            twinkleFast = true
        }
        
        // Medium twinkle
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            twinkleMedium = true
        }
        
        // Slow twinkle
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            twinkleSlow = true
        }
        
        // Drift X - slower for more noticeable movement
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            driftX = true
        }
        
        // Drift Y - different timing
        withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
            driftY = true
        }
        
        // Float - diagonal
        withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
            float = true
        }
    }
    
    private func startShootingStars() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            triggerShootingStar1()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
                triggerShootingStar2()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                triggerShootingStar3()
            }
        }
    }
    
    private func triggerShootingStar1() {
        shootingStar1Offset = -300
        shootingStar1Active = true
        
        withAnimation(.easeIn(duration: 0.6)) {
            shootingStar1Offset = 700
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            shootingStar1Active = false
        }
    }
    
    private func triggerShootingStar2() {
        shootingStar2Offset = -300
        shootingStar2Active = true
        
        withAnimation(.easeIn(duration: 0.8)) {
            shootingStar2Offset = 700
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            shootingStar2Active = false
        }
    }
    
    private func triggerShootingStar3() {
        shootingStar3Offset = -400
        shootingStar3Active = true
        
        withAnimation(.easeIn(duration: 0.5)) {
            shootingStar3Offset = 800
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shootingStar3Active = false
        }
    }
}

// Shooting Star View
private struct ShootingStarView: View {
    let color: Color
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6), color.opacity(0.2), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 120, height: 2)
            .shadow(color: color.opacity(0.6), radius: 4)
    }
}
// Previews

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
