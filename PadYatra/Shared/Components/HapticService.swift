// HapticService.swift
// Thin wrapper around UIKit haptic generators.
// Methods dispatch to main internally — callers need no actor annotation.
import UIKit

// MARK: - HapticService

enum HapticService {

    /// Use after a successful save (visit logged, data updated).
    static func success() {
        DispatchQueue.main.async {
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.success)
        }
    }

    /// Use on destructive actions (visit deleted).
    static func warning() {
        DispatchQueue.main.async {
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.warning)
        }
    }

    /// Use on high-impact moments (achievement unlocked).
    static func heavyImpact() {
        DispatchQueue.main.async {
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare()
            g.impactOccurred()
        }
    }

    /// Use for light UI interactions (chip tap, selection).
    static func lightImpact() {
        DispatchQueue.main.async {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        }
    }
}
