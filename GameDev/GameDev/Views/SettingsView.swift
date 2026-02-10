//
//  SettingsView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/10/26.
//

import SwiftUI

struct SettingsPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var audioPlayer = AudioPlayer.shared
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            // Popup card
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("SETTINGS")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Audio toggle
                HStack {
                    Image(systemName: audioPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(audioPlayer.isMuted ? .red : .green)
                        .frame(width: 30)
                    
                    Text("Sound")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { !audioPlayer.isMuted },
                        set: { audioPlayer.isMuted = !$0 }
                    ))
                    .labelsHidden()
                    .tint(.green)
                }
                .padding(.vertical, 8)
                
                Spacer()
            }
            .padding(24)
            .frame(width: 320, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }
}

#Preview {
    SettingsPopupView(isPresented: .constant(true))
}
