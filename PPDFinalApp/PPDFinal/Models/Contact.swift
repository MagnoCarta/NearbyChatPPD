import Foundation

struct Contact: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var location: Location
    var isOnline: Bool
    var distance: Double?

    init(id: UUID = UUID(), name: String, location: Location, isOnline: Bool = false, distance: Double? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.isOnline = isOnline
        self.distance = distance
    }
}
