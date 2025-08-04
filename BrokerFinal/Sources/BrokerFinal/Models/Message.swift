import Vapor
import Foundation

struct Message: Content, Equatable, Sendable {
    var id: UUID
    var senderID: UUID
    var receiverID: UUID
    var content: String
    var timestamp: Date
    var isRead: Bool

    init(id: UUID = UUID(), senderID: UUID, receiverID: UUID, content: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
