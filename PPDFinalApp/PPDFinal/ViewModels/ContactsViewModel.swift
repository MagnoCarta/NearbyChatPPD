import Foundation
import CoreLocation

/// View model responsible for keeping track of all known contacts in real time
/// and providing a filtered list of nearby contacts based on the user's
/// current location and desired radius.
@Observable
final class ContactsViewModel: WebSocketServiceDelegate {
    private let apiClient: APIClient
    private let webSocketService: WebSocketService

    private var userID: UUID?
    private var lastLocation: Location?
    private var radius: Double = 1000

    /// All contacts returned by the server.
    var allContacts: [Contact] = []
    /// Contacts filtered by `lastLocation` and `radius`.
    var contacts: [Contact] = []

    @MainActor
    init(apiClient: APIClient? = nil, webSocketService: WebSocketService? = nil) {
        self.apiClient = apiClient ?? APIClient(baseURL: URL(string: "http://127.0.0.1:8080")!)
        self.webSocketService = webSocketService ?? WebSocketService(baseURL: URL(string: "ws://127.0.0.1:8080/chat")!)
        Task { @WebSocketActor in
            self.webSocketService.addDelegate(self)
        }
    }

    private let fallbackDistance: Double = 100

    private func recalcContacts() {
        var updated: [Contact] = []
        if let loc = lastLocation {
            let userLocation = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            for contact in allContacts {
                guard contact.id != userID else { continue }
                let contactLoc = CLLocation(latitude: contact.location.latitude,
                                            longitude: contact.location.longitude)
                let distance = userLocation.distance(from: contactLoc)
                var copy = contact
                copy.distance = distance
                updated.append(copy)
            }
            allContacts = updated.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
            contacts = allContacts.filter { ($0.distance ?? .infinity) <= radius }
        } else {
            for contact in allContacts {
                var copy = contact
                copy.distance = fallbackDistance
                updated.append(copy)
            }
            allContacts = updated
            contacts = allContacts
        }
        print("Filtered nearby contacts: \(contacts.count)")
    }

    // MARK: - Public API

    func locationDidUpdate(_ location: Location) {
        lastLocation = location
        recalcContacts()
    }

    func radiusDidUpdate(_ newRadius: Double) {
        radius = newRadius
        recalcContacts()
    }

    @MainActor
    func syncContacts(userID: UUID, name: String?, location: Location, radius: Double) async {
        self.userID = userID
        lastLocation = location
        self.radius = radius
        do {
            let newContacts = try await apiClient.syncContacts(for: userID,
                                                               name: name,
                                                               location: location,
                                                               radius: radius)
            let unique = Dictionary(newContacts.map { ($0.id, $0) }) { first, _ in first }
            allContacts = Array(unique.values).filter { $0.id != userID }
            recalcContacts()
            print("Synced contacts from server")
        } catch {
            print("Failed to sync contacts: \(error)")
        }
    }

    // MARK: - WebSocketServiceDelegate

    nonisolated func webSocketService(_ service: WebSocketService, didReceiveContacts contacts: [Contact]) {
        Task { @MainActor in
            let unique = Dictionary(contacts.map { ($0.id, $0) }) { first, _ in first }
            self.allContacts = Array(unique.values).filter { $0.id != self.userID }
            self.recalcContacts()
            print("Received contacts update via WebSocket: \(contacts.count)")
        }
    }
}
