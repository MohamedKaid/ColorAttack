
import SwiftUI

struct ModeCardView: View {
    let mode: GameMode
    var isSelected: Bool = false
    let onStart: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var glowAnimation: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with Icon
            ZStack {
                // Gradient header background
                LinearGradient(
                    colors: [mode.color, mode.colorSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative circles
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: -60, y: -30)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .offset(x: 80, y: 40)
                
                VStack(spacing: 8) {
//                    // Mode Icon
                    Image(systemName: mode.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                    
                    // Title
                    Text(mode.title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                }
            }
            .frame(height: 140)
            .clipShape(
                RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
            )
            
            // Content
            VStack(spacing: 16) {
                // Difficulty Badge
                HStack {
                    Spacer()
                }
                .padding(.top, 12)
                
                // Rules
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(mode.rules.enumerated()), id: \.offset) { index, rule in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: mode.ruleIcons[index])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(mode.color)
                                .frame(width: 20)
                            Text(rule)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Start Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                        onStart()
                    }
                }) {
                    HStack {
                        Text("PLAY")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [mode.color, mode.colorSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: mode.color.opacity(0.4), radius: 8, y: 4)
                }
                .scaleEffect(isPressed ? 0.95 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
        }
        .frame(width: 260, height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isSelected ? mode.color : Color.clear,
                    lineWidth: 3
                )
        )
        .shadow(
            color: isSelected ? mode.color.opacity(0.4) : Color.black.opacity(0.15),
            radius: isSelected ? 20 : 10,
            y: isSelected ? 8 : 5
        )
        .overlay(
            // Glow effect for selected card
            RoundedRectangle(cornerRadius: 20)
                .stroke(mode.color.opacity(glowAnimation ? 0.6 : 0), lineWidth: 2)
                .blur(radius: 4)
                .opacity(isSelected ? 1 : 0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
    }
}

// Custom shape for rounded corners on specific sides
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Mode Card") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        HStack(spacing: 20) {
            ModeCardView(mode: .classic, isSelected: true) { }
            ModeCardView(mode: .rapid, isSelected: false) { }
        }
    }
}
