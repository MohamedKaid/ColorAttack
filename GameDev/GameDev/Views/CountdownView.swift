//
//  CountdownView.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/8/26.
//

import SwiftUI

struct CountdownView: View {
    let onComplete: () -> Void
    
    @State private var count: Int = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Countdown (Grouped both views into 1)
            Group {
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 150, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("GO!")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private func startCountdown() {
        animateNumber()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            count -= 1
            
            if count >= 0 {
                animateNumber()
            }
            
            if count < 0 {
                timer.invalidate()
                onComplete()
            }
        }
    }
    
    private func animateNumber() {
        // Reset
        scale = 0.5
        opacity = 0
        
        // Fading in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Fading out 
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 1.5
                opacity = 0
            }
        }
    }
}

#Preview {
    CountdownView {
        print("Done!")
    }
}
