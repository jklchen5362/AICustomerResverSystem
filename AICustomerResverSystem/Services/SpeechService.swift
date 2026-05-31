//  SpeechService.swift
//  AICustomerResverSystem
//

import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    var isPlaying = false
    var currentText: String = ""
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure Audio Session for active playback (even on silent switch)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session for SpeechService: \(error)")
        }
        
        currentText = text
        let utterance = AVSpeechUtterance(string: text)
        
        // Choose Traditional Chinese voice
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        
        // Refined parameters for luxury clinic ambiance (softer, slower, elegant delivery)
        utterance.rate = 0.48 // Standard speed is 0.5; 0.48 is slightly slower and more composed
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for a warmer, friendly feel
        utterance.volume = 1.0
        
        isPlaying = true
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            SpeechService.shared.isPlaying = false
            SpeechService.shared.currentText = ""
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            SpeechService.shared.isPlaying = false
            SpeechService.shared.currentText = ""
        }
    }
}
