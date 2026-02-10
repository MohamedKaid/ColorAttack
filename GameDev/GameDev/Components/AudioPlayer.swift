//
//  AudioPlayer.swift
//  GameDev
//
//  Created by Mohamed Shahbain on 2/9/26.
//

import SwiftUI
import Combine
import AVFoundation

class AudioPlayer: ObservableObject {
    //instance of musicplayer class
    static let shared = AudioPlayer()

    //instance of audioplayer class(private means it can't be accessed outside of class)
    private var player: AVAudioPlayer?

    private var currentFileName: String?
    private var currentVolume: Float = 0.5
    
    // Published so UI can react to changes
     @Published var isMuted: Bool {
         didSet {
             UserDefaults.standard.set(isMuted, forKey: "audioMuted")
             if isMuted {
                 player?.volume = 0
             } else {
                 player?.volume = currentVolume
             }
         }
     }
     
    
    init() {
        
        self.isMuted = UserDefaults.standard.bool(forKey: "audioMuted")

           // Configure audio session for playback on iPhone
           do {
               try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
               try AVAudioSession.sharedInstance().setActive(true)
           } catch {
               print("Failed to set audio session:", error)
           }
       }
    
    //open the music file
    func playMusic(_ fileName: String, type: String = "wav", volume: Float = 0.5, loops: Int = -1) {
           guard let url = Bundle.main.url(forResource: fileName, withExtension: type) else {
               print("ERROR: Could not find music file \(fileName).\(type)")
               return
           }
           
           do {
               player = try AVAudioPlayer(contentsOf: url)
               currentFileName = fileName
               currentVolume = volume
               player?.volume = isMuted ? 0 : volume
               player?.numberOfLoops = loops
               player?.play()
           } catch {
               print("ERROR: Could not play music file:", error)
           }
    }

    func stop() {
        player?.stop()
        player = nil
        currentFileName = nil
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
}
