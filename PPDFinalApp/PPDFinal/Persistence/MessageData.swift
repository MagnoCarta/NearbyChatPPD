import Foundation
import SwiftData

@Model
final class MessageData {
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

    convenience init(from message: Message) {
        self.init(id: message.id, senderID: message.senderID, receiverID: message.receiverID, content: message.content, timestamp: message.timestamp, isRead: message.isRead)
    }

    func toMessage() -> Message {
        Message(id: id,
                senderID: senderID,
                receiverID: receiverID,
                content: content,
                timestamp: timestamp,
                isRead: isRead)
    }
}
