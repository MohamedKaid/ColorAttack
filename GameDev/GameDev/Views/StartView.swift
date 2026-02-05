//
//  StartView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/4/26.
//

import SwiftUI

struct StartView: View {

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background Image
                Image("mode_select_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                VStack(spacing: 24) {

                    Spacer()

                    //Placeholder Title
                    VStack(spacing: 4) {
                        Text("COLOR")
                            .font(.system(size: 72, weight: .heavy))
                            .foregroundColor(.orange)

                        Text("ATTACK")
                            .font(.system(size: 64, weight: .heavy))
                            .foregroundColor(.cyan)
                    }

//                    //Placeholder Shapes
//                    HStack(spacing: 20) {
//                        ForEach(0..<4) { _ in
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color.white.opacity(0.25))
//                                .frame(width: 70, height: 70)
//                        }
//                    }

                    Spacer()

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
        }
    }
}

#Preview() {
    NavigationStack {
        StartView()
    }
}
