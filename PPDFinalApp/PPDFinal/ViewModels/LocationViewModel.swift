import Foundation
import CoreLocation

@Observable
final class LocationViewModel {
    private let service: LocationService
    private var apiClient: APIClient?
    private var userID: UUID?
    private var name: String?
    private var radius: Double = 1000

    init(service: LocationService = LocationService()) {
        self.service = service
    }

    var authorizationStatus: CLAuthorizationStatus {
        service.authorizationStatus
    }

    var lastLocation: CLLocation? {
        service.lastLocation
    }

    func startUpdates() {
        service.startUpdatingLocation()
        print("Location updates started")
    }

    func stopUpdates() {
        service.stopUpdatingLocation()
        print("Location updates stopped")
    }

    /// Starts forwarding location updates to the broker for the given user.
    @MainActor
    func bindToBroker(user: User, settings: Settings, apiClient: APIClient? = nil) {
        // Use IPv4 localhost so that the simulator can reach the server when it
        // binds only to 127.0.0.1.
        self.apiClient = apiClient ?? APIClient(baseURL: URL(string: "http://127.0.0.1:8080")!)
        self.userID = user.id
        self.name = user.username
        self.radius = settings.radius
        print("Bound location service to broker for user: \(user.username)")
        service.onLocationUpdate = { [weak self] location in
            Task { await self?.notifyBroker(location: location) }
        }
        if let location = service.lastLocation {
            Task { await notifyBroker(location: location) }
        }
    }

    /// Updates the radius used when notifying the broker.
    func updateRadius(_ newRadius: Double) {
        radius = newRadius
        print("Updated radius to \(newRadius)")
        if let location = service.lastLocation {
            Task { await notifyBroker(location: location) }
        }
    }

    @APIActor
    private func notifyBroker(location: CLLocation) async {
        guard let client = apiClient, let userID else { return }
        let loc = Location(latitude: location.coordinate.latitude,
                           longitude: location.coordinate.longitude)
        _ = try? await client.syncContacts(for: userID,
                                           name: name,
                                           location: loc,
                                           radius: radius)
        print("Notified broker of location: \(loc.latitude), \(loc.longitude)")
    }
}
