import AudioToolbox
import Foundation

#if os(iOS)
    import UIKit
#endif

// MARK: - Feedback (音效與觸覺回饋)
// 集中管理與畫面狀態無關的聲音／震動回饋
enum Feedback {
    // Fires a burst of heavy impacts to produce a stronger, heavier "thud" than a single tap
    static func strongHaptic() {
        #if os(iOS)
            Task { @MainActor in
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.prepare()
                for _ in 0..<3 {
                    generator.impactOccurred(intensity: 1.0)
                    try? await Task.sleep(for: .milliseconds(45))
                }
            }
        #endif
    }

    // Plays a system chime when the countdown completes
    static func playCompletionSound() {
        AudioServicesPlaySystemSound(SystemSoundID(Compeletion.soudEffectID))
        #if os(iOS)
            playContinuousVibration(for: Compeletion.vibrateDuration)
        #endif
    }

    // Repeats the system vibration to approximate a continuous buzz for the given duration
    static func playContinuousVibration(for duration: TimeInterval) {
        #if os(iOS)
            Task { @MainActor in
                let interval: TimeInterval = 0.5  // each vibrate pulse lasts ~0.4s
                let repeats = max(1, Int(duration / interval))
                for _ in 0..<repeats {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    try? await Task.sleep(for: .seconds(interval))
                }
            }
        #endif
    }
}
