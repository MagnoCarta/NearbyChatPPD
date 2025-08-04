import Fluent
import Vapor

final class UserModel: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "is_online")
    var isOnline: Bool

    init() { }

    init(id: UUID? = nil, name: String, latitude: Double, longitude: Double, isOnline: Bool = true) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isOnline = isOnline
    }

    var location: Location {
        get { Location(latitude: latitude, longitude: longitude) }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}
