import Foundation
import CoreLocation
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@MainActor @Observable
final class LocationTriggerService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationTriggerService()

    private let locationManager = CLLocationManager()
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var monitoredRegionCount: Int = 0
    var currentLocation: CLLocationCoordinate2D?

    override private init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Request a single location update for solar calculations.
    func requestCurrentLocation() {
        locationManager.requestLocation()
    }

    // MARK: - Task Location Reminders

    func startMonitoringTask(_ task: TaskItem) {
        guard let lat = task.locationLatitude,
              let lon = task.locationLongitude else { return }
        let radius = task.locationRadius > 0 ? task.locationRadius : 200.0

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: radius,
            identifier: "task-\(task.id.uuidString)"
        )

        region.notifyOnEntry = task.locationDirection == .arrive
        region.notifyOnExit = task.locationDirection == .leave

        locationManager.startMonitoring(for: region)
        monitoredRegionCount = locationManager.monitoredRegions.count
    }

    func stopMonitoringTask(_ task: TaskItem) {
        let identifier = "task-\(task.id.uuidString)"
        let regions = locationManager.monitoredRegions.filter { $0.identifier == identifier }
        for region in regions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegionCount = locationManager.monitoredRegions.count
    }

    func refreshTaskMonitoring(context: ModelContext) {
        // Remove all task-based regions
        for region in locationManager.monitoredRegions where region.identifier.hasPrefix("task-") {
            locationManager.stopMonitoring(for: region)
        }

        // Re-register active task location reminders
        let descriptor = FetchDescriptor<TaskItem>()
        guard let tasks = try? context.fetch(descriptor) else { return }

        let locationTasks = tasks.filter { $0.status == .todo && $0.locationLatitude != nil && $0.locationLongitude != nil }
        for task in locationTasks {
            startMonitoringTask(task)
        }
        monitoredRegionCount = locationManager.monitoredRegions.count
    }

    // MARK: - Region Monitoring

    func startMonitoring(trigger: Trigger) {
        guard let lat = trigger.latitude,
              let lon = trigger.longitude,
              let radius = trigger.radiusMeters else { return }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            radius: radius,
            identifier: trigger.id.uuidString
        )

        region.notifyOnEntry = trigger.geoDirection == .enter
        region.notifyOnExit = trigger.geoDirection == .leave

        locationManager.startMonitoring(for: region)
        monitoredRegionCount = locationManager.monitoredRegions.count
    }

    func stopMonitoring(trigger: Trigger) {
        let regions = locationManager.monitoredRegions.filter { $0.identifier == trigger.id.uuidString }
        for region in regions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegionCount = locationManager.monitoredRegions.count
    }

    func refreshAllMonitoring(context: ModelContext) {
        // Stop all current monitoring
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }

        // Re-register active geo triggers
        let descriptor = FetchDescriptor<Trigger>()
        guard let triggers = try? context.fetch(descriptor) else { return }

        let geoTriggers = triggers.filter { $0.isEnabled && $0.triggerType == .geolocation }
        for trigger in geoTriggers {
            startMonitoring(trigger: trigger)
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let regionId = region.identifier
        Task { @MainActor in
            handleRegionEvent(regionId: regionId, direction: .enter)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let regionId = region.identifier
        Task { @MainActor in
            handleRegionEvent(regionId: regionId, direction: .leave)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            #if os(iOS)
            let authorized = status == .authorizedWhenInUse || status == .authorizedAlways
            #else
            let authorized = status == .authorizedAlways || status == .authorized
            #endif
            if authorized {
                requestCurrentLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            currentLocation = coordinate
            SolarService.shared.update(for: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location request failed — solar service will use defaults
    }

    private func handleRegionEvent(regionId: String, direction: GeoDirection) {
        if regionId.hasPrefix("task-") {
            // Task location reminder
            let taskIdString = String(regionId.dropFirst(5))
            let directionLabel = direction == .enter ? "arrived at" : "left"
            NotificationCenter.default.post(
                name: .taskLocationTriggered,
                object: nil,
                userInfo: ["taskId": taskIdString, "direction": directionLabel]
            )
        } else {
            // Automation trigger
            NotificationCenter.default.post(
                name: .geoTriggerFired,
                object: nil,
                userInfo: ["triggerId": regionId, "direction": direction.rawValue]
            )
        }
    }
}

extension Notification.Name {
    static let geoTriggerFired = Notification.Name("geoTriggerFired")
    static let taskLocationTriggered = Notification.Name("taskLocationTriggered")
}
