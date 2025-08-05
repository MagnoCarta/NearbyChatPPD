import Foundation

struct Message: Identifiable, Codable, Equatable {
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
    
    private enum CodingKeys: String, CodingKey {
        case id, senderID, receiverID, content, timestamp, isRead
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        senderID = try container.decode(UUID.self, forKey: .senderID)
        receiverID = try container.decode(UUID.self, forKey: .receiverID)
        content = try container.decode(String.self, forKey: .content)
        isRead = try container.decode(Bool.self, forKey: .isRead)

        if let timeString = try? container.decode(String.self, forKey: .timestamp) {
            if let date = ISO8601DateFormatter().date(from: timeString) {
                timestamp = date
            } else if let interval = Double(timeString) {
                timestamp = Date(timeIntervalSince1970: interval)
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .timestamp,
                    in: container,
                    debugDescription: "Invalid date format"
                )
            }
        } else if let timeInterval = try? container.decode(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timeInterval)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .timestamp,
                in: container,
                debugDescription: "Expected string or double for timestamp"
            )
        }
    }
}
