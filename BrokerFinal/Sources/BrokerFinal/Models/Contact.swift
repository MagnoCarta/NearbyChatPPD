import Foundation
import Vapor

struct Contact: Content, Identifiable, Equatable {
    var id: UUID
    var name: String
    var location: Location
    var isOnline: Bool
    var distance: Double?
}
