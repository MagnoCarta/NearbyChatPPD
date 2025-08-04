import Foundation
import Vapor

struct UserDTO: Content {
    let id: UUID
    let name: String
    let location: Location
    let status: UserStatus
}
