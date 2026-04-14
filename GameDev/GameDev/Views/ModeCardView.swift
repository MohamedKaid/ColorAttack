import SwiftUI
import GameKit

struct ModeCardView: View {
    let mode: GameMode
    var isSelected: Bool = false
    let onStart: () -> Void

    @State private var isPressed: Bool = false
    @State private var glowAnimation: Bool = false
    @State private var showLeaderboard: Bool = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width
            let headerHeight = cardWidth * 0.5
            let iconSize = cardWidth * 0.17
            let titleSize = cardWidth * 0.1
            let ruleSize = cardWidth * 0.05
            let playSize = cardWidth * 0.07

            VStack(spacing: 0) {
                // Header with Icon
                ZStack {
                    // Rainbow gradient for Frenzy, standard gradient for others
                    if let rainbowColors = mode.rainbowColors {
                        LinearGradient(
                            colors: rainbowColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [mode.color, mode.colorSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }

                    // Decorative circles
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: cardWidth * 0.38, height: cardWidth * 0.38)
                        .offset(x: -cardWidth * 0.23, y: -cardWidth * 0.11)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: cardWidth * 0.23, height: cardWidth * 0.23)
                        .offset(x: cardWidth * 0.3, y: cardWidth * 0.15)

                    VStack(spacing: cardWidth * 0.03) {
                        Image(systemName: mode.icon)
                            .font(.system(size: iconSize, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 2)

                        Text(mode.title)
                            .font(.system(size: titleSize, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                    }

                    // Leaderboard Button
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showLeaderboard = true
                            } label: {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: cardWidth * 0.054, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(cardWidth * 0.03)
                                    .background(Circle().fill(Color.black.opacity(0.25)))
                            }
                            .padding(cardWidth * 0.038)
                        }
                        Spacer()
                    }
                }
                .frame(height: headerHeight)
                .clipShape(
                    RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
                )

                // Content
                VStack(spacing: cardWidth * 0.06) {

                    // Rules
                    VStack(alignment: .leading, spacing: cardWidth * 0.038) {
                        ForEach(Array(mode.rules.enumerated()), id: \.offset) { index, rule in
                            HStack(alignment: .top, spacing: cardWidth * 0.038) {
                                Image(systemName: mode.ruleIcons[index])
                                    .font(.system(size: ruleSize, weight: .semibold))
                                    .foregroundColor(mode.color)
                                    .frame(width: cardWidth * 0.077)
                                    .padding(.top, 1)
                                Text(rule)
                                    .font(.system(size: ruleSize, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Play Button
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
                                .font(.system(size: playSize, weight: .bold, design: .rounded))
                            Image(systemName: "play.fill")
                                .font(.system(size: playSize * 0.78, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, cardWidth * 0.054)
                        .background(
                            Group {
                                if let rainbowColors = mode.rainbowColors {
                                    LinearGradient(
                                        colors: rainbowColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [mode.color, mode.colorSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: mode.color.opacity(0.4), radius: 8, y: 4)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1)
                }
                .padding(cardWidth * 0.06)
                .background(Color(.systemBackground))
            }
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
            .sheet(isPresented: $showLeaderboard) {
                LeaderboardView(leaderboardID: mode.leaderboardID)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Game Center Leaderboard

struct LeaderboardView: UIViewControllerRepresentable {
    let leaderboardID: String

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

// MARK: - Custom Rounded Corner Shape

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

// MARK: - Preview

#Preview("Mode Card") {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        HStack(spacing: 20) {
            ModeCardView(mode: .frenzy, isSelected: true) { }
            ModeCardView(mode: .classic, isSelected: false) { }
        }
    }
}
