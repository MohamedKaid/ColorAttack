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
        VStack(spacing: 0) {
            // Header with Icon
            ZStack {
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
                    Image(systemName: mode.icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)

                    Text(mode.title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                }

                // Leaderboard Button — top right corner of header
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showLeaderboard = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.25)))
                        }
                        .padding(10)
                    }
                    Spacer()
                }
            }
            .frame(height: 140)
            .clipShape(
                RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
            )

            // Content
            VStack(spacing: 16) {

                // Rules — no fixed height, grows with content
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(mode.rules.enumerated()), id: \.offset) { index, rule in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: mode.ruleIcons[index])
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(mode.color)
                                .frame(width: 20)
                                .padding(.top, 1)
                            Text(rule)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true) // key fix — allows text to wrap fully
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
            .padding(16)
            .background(Color(.systemBackground))
        }
        // Removed fixed height — card grows to fit content
        .frame(width: 260)
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
            ModeCardView(mode: .classic, isSelected: true) { }
            ModeCardView(mode: .chaos, isSelected: false) { }
        }
    }
}
