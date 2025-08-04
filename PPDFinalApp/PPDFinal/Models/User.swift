import Foundation
import CoreLocation

enum UserStatus: String, Codable {
    case online
    case offline
    case away
}

struct Location: Codable, Equatable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct User: Identifiable, Codable, Equatable {
    var id: UUID
    var username: String
    var location: Location
    var status: UserStatus

    init(id: UUID = UUID(), username: String, location: Location, status: UserStatus = .offline) {
        self.id = id
        self.username = username
        self.location = location
        self.status = status
    }
}
