import Foundation

struct Settings: Codable, Equatable {
    var radius: Double
    var notificationsEnabled: Bool

    init(radius: Double = 1000, notificationsEnabled: Bool = true) {
        self.radius = radius
        self.notificationsEnabled = notificationsEnabled
    }
}
