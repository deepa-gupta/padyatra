// HapticService.swift
// Thin wrapper around UIKit haptic generators.
// All methods are main-thread safe — callers must be on @MainActor.
import UIKit

// MARK: - HapticService

@MainActor
enum HapticService {

    /// Use after a successful save (visit logged, data updated).
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    /// Use on destructive actions (visit deleted).
    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }

    /// Use on high-impact moments (achievement unlocked).
    static func heavyImpact() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred()
    }

    /// Use for light UI interactions (chip tap, selection).
    static func lightImpact() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }
}
