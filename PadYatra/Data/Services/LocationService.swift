// LocationService.swift
// Wraps CLLocationManager and publishes the user's current location.
// Permission is requested lazily — only when the user taps "Near Me".
import CoreLocation
import OSLog
import SwiftUI

@MainActor
final class LocationService: NSObject, ObservableObject {

    // MARK: - Published

    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    // MARK: - Private

    private let manager = CLLocationManager()
    private let logger = Logger(subsystem: "com.padyatra", category: "LocationService")

    // MARK: - Init

    override init() {
        // Start with .notDetermined; setting manager.delegate below triggers
        // locationManagerDidChangeAuthorization immediately with the real status.
        authorizationStatus = .notDetermined
        super.init()
        manager.delegate = self              // triggers delegate callback synchronously
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100 // metres — avoid excessive updates
    }

    // MARK: - Public API

    /// Requests When In Use permission. Call only in response to a direct user gesture.
    func requestWhenInUsePermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            logger.warning("Location permission denied or restricted — user must update in Settings.")
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorised — start updates if not already running.
            startUpdating()
        @unknown default:
            logger.error("Unknown CLAuthorizationStatus value — ignoring.")
        }
    }

    /// Returns the straight-line distance from the user's location to the temple, or nil if
    /// the user's location is unknown.
    func distance(to temple: Temple) -> CLLocationDistance? {
        guard let userLocation,
              let lat = temple.location.latitude,
              let lon = temple.location.longitude else { return nil }
        return userLocation.distance(from: CLLocation(latitude: lat, longitude: lon))
    }

    // MARK: - Private

    private func startUpdating() {
        manager.startUpdatingLocation()
        logger.info("Location updates started.")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            self.logger.info("Location authorisation changed: \(status.rawValue)")
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdating()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.userLocation = latest
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        let description = error.localizedDescription
        Task { @MainActor in
            self.logger.error("Location update failed: \(description)")
        }
    }
}
