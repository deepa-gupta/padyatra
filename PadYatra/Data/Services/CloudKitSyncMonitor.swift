// CloudKitSyncMonitor.swift
// Observes NSPersistentCloudKitContainer sync events and publishes isSyncing.
// SwiftData + CloudKit already handles offline queuing natively — this service
// only surfaces sync state to the UI.
import Foundation
import CoreData
import OSLog

// MARK: - CloudKitSyncMonitor

@MainActor
final class CloudKitSyncMonitor: ObservableObject {

    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncFailed: Bool = false

    private let logger = Logger(subsystem: "com.padyatra", category: "CloudKitSyncMonitor")
    // Held in a nonisolated wrapper so deinit can remove the observer safely
    private let token = ObserverToken()

    init() {
        let observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Extract only Sendable (Bool) values before crossing the actor boundary
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }
            let started = event.endDate == nil
            let failed  = event.error != nil
            Task { @MainActor [weak self] in
                self?.apply(started: started, failed: failed)
            }
        }
        token.value = observer
    }

    // MARK: - Private

    private func apply(started: Bool, failed: Bool) {
        if started {
            isSyncing = true
            lastSyncFailed = false
            logger.debug("CloudKit sync started.")
        } else {
            isSyncing = false
            lastSyncFailed = failed
            if failed {
                logger.warning("CloudKit sync finished with error.")
            } else {
                logger.debug("CloudKit sync finished successfully.")
            }
        }
    }
}

// MARK: - ObserverToken

/// Reference wrapper so nonisolated deinit can hold and remove the observer.
private final class ObserverToken: @unchecked Sendable {
    var value: (any NSObjectProtocol)?
    deinit {
        if let value { NotificationCenter.default.removeObserver(value) }
    }
}
