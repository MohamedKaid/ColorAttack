//
//  CustomLeaderboardView.swift
//  Color Frenzy
//
//  Drop-in replacement for LeaderBoardView.
//  Shows a styled, scrollable leaderboard for all five modes
//  fetched from Game Center, matching the Color Frenzy visual style.
//

import SwiftUI
import GameKit

// MARK: - Entry Point (replaces LeaderBoardView)

struct CustomLeaderboardView: View {
    var initialMode: GameMode = .classic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LeaderboardSheetView(initialMode: initialMode, onDismiss: { dismiss() })
    }
}

// MARK: - Sheet View

struct LeaderboardSheetView: View {
    let initialMode: GameMode
    let onDismiss: () -> Void

    @State private var selectedMode: GameMode = .classic
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            // Background — same dark gradient as the rest of the app
            LinearGradient(
                colors: [Color(hex: "0D0D1A"), Color(hex: "12122A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerBar

                // Mode Tabs
                modeTabs
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Content
                ZStack {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(message: error)
                    } else if entries.isEmpty {
                        emptyView
                    } else {
                        entriesList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            selectedMode = initialMode
        }
        .task(id: selectedMode) {
            await loadEntries()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("LEADERBOARD")
                .font(.custom("Candy-Planet", size: 28))
                .foregroundColor(.white)
                .shadow(color: selectedMode.color.opacity(0.8), radius: 8, y: 2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Mode Tabs

    private var modeTabs: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GameMode.allCases) { mode in
                        ModeTab(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMode = mode
                                proxy.scrollTo(mode.id, anchor: .center)
                            }
                        }
                        .id(mode.id)
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(selectedMode.id, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedMode) { _, newMode in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newMode.id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(entries) { entry in
                    LeaderboardRowView(entry: entry, modeColor: selectedMode.color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: selectedMode.color))
                .scaleEffect(1.4)
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(selectedMode.color.opacity(0.5))
            Text("No scores yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
            Text("Be the first to play \(selectedMode.title)!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange.opacity(0.7))
            Text("Couldn't load scores")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                Task { await loadEntries() }
            }
            .font(.subheadline.bold())
            .foregroundColor(selectedMode.color)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(selectedMode.color.opacity(0.15))
            )
        }
    }

    // MARK: - Data Loading

    private func loadEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            entries = try await GameCenterLeaderboardService.loadTopEntries(
                leaderboardID: selectedMode.leaderboardID,
                top: 25
            )
        } catch {
            errorMessage = error.localizedDescription
            entries = []
        }

        isLoading = false
    }
}

// MARK: - Mode Tab Button

private struct ModeTab: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isSelected ? mode.color : Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Row View

private struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let modeColor: Color

    private var rankBadgeColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "FFD700")   // Gold
        case 2: return Color(hex: "C0C0C0")   // Silver
        case 3: return Color(hex: "CD7F32")   // Bronze
        default: return Color.white.opacity(0.15)
        }
    }

    private var rankTextColor: Color {
        switch entry.rank {
        case 1, 2, 3: return .black
        default: return .white.opacity(0.7)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankBadgeColor)
                    .frame(width: 40, height: 40)

                Text("\(entry.rank)")
                    .font(.system(size: entry.rank >= 10 ? 13 : 15, weight: .black))
                    .foregroundColor(rankTextColor)
            }

            // Name + YOU tag
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if entry.isLocalPlayer {
                    Text("YOU")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.white)
                        )
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                Text("pts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    entry.isLocalPlayer
                        ? modeColor.opacity(0.18)
                        : Color.white.opacity(0.06)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            entry.isLocalPlayer
                                ? modeColor.opacity(0.45)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        // Subtle glow on local player row
        .shadow(
            color: entry.isLocalPlayer ? modeColor.opacity(0.25) : .clear,
            radius: 8
        )
    }
}

// MARK: - Preview

#Preview {
    CustomLeaderboardView()
}
