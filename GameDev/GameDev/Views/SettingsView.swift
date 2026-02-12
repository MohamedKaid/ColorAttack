//
//  SettingsView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/10/26.
//

import SwiftUI

struct SettingsPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var audio = AudioPlayer.shared

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 24) {
                // Title
                Text("SETTINGS")
                    .font(.custom("Candy-Planet", size: 28))
                    .foregroundColor(.white)

                // ✅ Music toggle
                HStack {
                    Image(systemName: audio.isMusicMuted ? "speaker.slash.fill" : "music.note")
                        .font(.title2)
                        .foregroundColor(audio.isMusicMuted ? .red : .green)
                        .frame(width: 30)

                    Text("Music")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { !audio.isMusicMuted },
                        set: { _ in audio.toggleMusicMute() }
                    ))
                    .labelsHidden()
                    .tint(.green)
                }
                .padding(.horizontal, 20)

                // ✅ SFX toggle
                HStack {
                    Image(systemName: audio.isSFXMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(audio.isSFXMuted ? .red : .green)
                        .frame(width: 30)

                    Text("Sound Effects")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { !audio.isSFXMuted },
                        set: { _ in audio.toggleSFXMute() }
                    ))
                    .labelsHidden()
                    .tint(.green)
                }
                .padding(.horizontal, 20)

                // Close button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("DONE")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 360)
        }
    }
}

#Preview("Settings Popup") {
    SettingsPopupView(isPresented: .constant(true))
}
