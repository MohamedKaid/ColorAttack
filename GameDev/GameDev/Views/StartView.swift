//
//  StartView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI
import Lottie

struct StartView: View {

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
        }
        .onAppear(){
        // AudioPlayer.shared.playMusic("Game Theme 3")
        }
    }
}

#Preview {
    NavigationStack {
        StartView()
    }
}
