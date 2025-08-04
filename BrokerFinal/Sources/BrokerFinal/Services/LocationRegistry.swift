import Foundation
import Logging

actor LocationRegistry {
    struct Entry {
        var location: Location
        var radius: Double
        var status: UserStatus
        var name: String

        var isOnline: Bool { status != .offline }
    }

    private var entries: [UUID: Entry] = [:]
    private let logger = Logger(label: "LocationRegistry")

    func update(userID: UUID, name: String, location: Location, radius: Double) {
        logger.info("Update location", metadata: [
            "userID": .string(userID.uuidString),
            "radius": .string("\(radius)"),
            "lat": .string("\(location.latitude)"),
            "lon": .string("\(location.longitude)")
        ])
        if var existing = entries[userID] {
            existing.location = location
            existing.radius = radius
            existing.name = name
            existing.status = .online
            entries[userID] = existing
        } else {
            entries[userID] = Entry(location: location, radius: radius, status: .online, name: name)
        }
    }

    func setOnline(_ userID: UUID, isOnline: Bool) {
        updateStatus(userID, status: isOnline ? .online : .offline)
    }

    func updateStatus(_ userID: UUID, status: UserStatus) {
        logger.info("Status update", metadata: ["userID": .string(userID.uuidString), "status": .string(status.rawValue)])
        if var entry = entries[userID] {
            entry.status = status
            entries[userID] = entry
        } else {
            entries[userID] = Entry(location: Location(latitude: 0, longitude: 0),
                                   radius: 0,
                                   status: status,
                                   name: userID.uuidString)
        }
    }

    func contacts(for userID: UUID) -> [Contact] {
        guard let me = entries[userID] else { return [] }
        var result: [Contact] = []
        for (id, entry) in entries where id != userID {
            let distance = me.location.distance(to: entry.location)
            if distance <= me.radius {
                result.append(Contact(id: id, name: entry.name, location: entry.location, isOnline: entry.isOnline, distance: distance))
            }
        }
        return result.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
    }

    func allContacts() -> [Contact] {
        entries.map { id, entry in
            Contact(id: id, name: entry.name, location: entry.location, isOnline: entry.isOnline, distance: nil)
        }
    }

    func status(for userID: UUID) -> UserStatus? {
        entries[userID]?.status
    }

    func name(for userID: UUID) -> String? {
        entries[userID]?.name
    }
}
