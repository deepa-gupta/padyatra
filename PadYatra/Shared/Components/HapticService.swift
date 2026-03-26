// HapticService.swift
// Thin wrapper around UIKit haptic generators.
// Methods are nonisolated and schedule work on the MainActor via Task.
import UIKit

// MARK: - HapticService

enum HapticService {

    /// Use after a successful save (visit logged, data updated).
    static func success() {
        Task { @MainActor in
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.success)
        }
    }

    /// Use on destructive actions (visit deleted).
    static func warning() {
        Task { @MainActor in
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.warning)
        }
    }

    /// Use on high-impact moments (achievement unlocked).
    static func heavyImpact() {
        Task { @MainActor in
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare()
            g.impactOccurred()
        }
    }

    /// Use for light UI interactions (chip tap, selection).
    static func lightImpact() {
        Task { @MainActor in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        }
    }
}
