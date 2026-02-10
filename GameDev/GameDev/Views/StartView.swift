//
//  StartView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI
import Lottie

struct StartView: View {
    
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            GameBackground(mode: .menu)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer()
                
                // Title Image
                Image("Title")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 600)
                    .padding(.horizontal, 40)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                // Animated Shapes Bouncing
                LottieView(animation: .named("finalShape"))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 280, height: 280)


                // Start Button
                NavigationLink {
                    ModeSelectionView()
                } label: {
                    Text("START")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 260, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(radius: 12)
                }

                Spacer(minLength: 40)
            }
            
            // Settings button (top right)
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
            
            // Settings popup overlay
            if showSettings {
                SettingsPopupView(isPresented: $showSettings)
                    .transition(.opacity)
            }
        }
        .onAppear(){
            AudioPlayer.shared.playMusic("Game Theme 3")
        }
    }
}

#Preview {
    NavigationStack {
        StartView()
    }
}
