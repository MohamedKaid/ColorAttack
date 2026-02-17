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
    private var musicPlayer: AVAudioPlayer?
    
    // Dictionary of SFX players — allows multiple SFX to overlap
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    private var currentMusicFileName: String?
    private var currentMusicVolume: Float = 0.5
    private var currentSFXVolume: Float = 1.0
    
    // Published so UI can react to changes
    @Published var isMusicMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMusicMuted, forKey: "musicMuted")
            if isMusicMuted {
                musicPlayer?.volume = 0
            } else {
                musicPlayer?.volume = currentMusicVolume
            }
        }
    }
    
    // Separate mute for sound effects
    @Published var isSFXMuted: Bool {
        didSet {
            UserDefaults.standard.set(isSFXMuted, forKey: "sfxMuted")
        }
    }
    
    // Convenience: check if everything is muted
    var isAllMuted: Bool {
        isMusicMuted && isSFXMuted
    }
    
    init() {
        self.isMusicMuted = UserDefaults.standard.bool(forKey: "musicMuted")
        self.isSFXMuted = UserDefaults.standard.bool(forKey: "sfxMuted")

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
        // Don't restart the same track if it's already playing
        if currentMusicFileName == fileName, musicPlayer?.isPlaying == true {
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: type) else {
            print("ERROR: Could not find music file \(fileName).\(type)")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            currentMusicFileName = fileName
            currentMusicVolume = volume
            musicPlayer?.volume = isMusicMuted ? 0 : volume
            musicPlayer?.numberOfLoops = loops
            musicPlayer?.play()
        } catch {
            print("ERROR: Could not play music file:", error)
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicFileName = nil
    }
    
    // Pause music
    func pauseMusic() {
        musicPlayer?.pause()
    }
    
    // Resume music
    func resumeMusic() {
        guard let player = musicPlayer else { return }
        player.volume = isMusicMuted ? 0 : currentMusicVolume
        player.play()
    }
    
    func toggleMusicMute() {
        isMusicMuted.toggle()
    }
    
    // Sound Effects
    
    // Play a one-shot sound effect
    func playSFX(_ fileName: String, type: String = "mp3", volume: Float = 1.0) {
        guard !isSFXMuted else { return }
        
        let url = Bundle.main.url(forResource: fileName, withExtension: type)
        guard let url else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.numberOfLoops = 0
            player.prepareToPlay()
            //let success = player.play()
            sfxPlayers[fileName] = player
        } catch {
            print("4. Error: \(error)")
        }
    }
    
    func stopSFX(_ fileName: String) {
        sfxPlayers[fileName]?.stop()
        sfxPlayers.removeValue(forKey: fileName)
    }
    
    // Stop all sound effects
    func stopAllSFX() {
        sfxPlayers.values.forEach { $0.stop() }
        sfxPlayers.removeAll()
    }
    
    func toggleSFXMute() {
        isSFXMuted.toggle()
    }
    
    // Stop Everything
    
    func stopAll() {
        stopMusic()
        stopAllSFX()
    }
    
    // Mute/unmute everything at once
    func toggleAllMute() {
        if isAllMuted {
            isMusicMuted = false
            isSFXMuted = false
        } else {
            isMusicMuted = true
            isSFXMuted = true
        }
    }
}
