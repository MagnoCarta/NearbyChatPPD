import Foundation
import Vapor
import Redis
import Logging

/// Simple Redis-backed message queue storing messages for offline users.
actor RedisMessageQueue: MessageQueue {
    let client: any RedisClient
    private let logger = Logger(label: "RedisMessageQueue")

    init(client: any RedisClient) {
        self.client = client
    }
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func enqueue(_ message: Message, for userID: UUID) async throws {
        let data = try encoder.encode(message)
        let key = RedisKey("queue:\(userID.uuidString)")
        let string = String(data: data, encoding: .utf8) ?? ""
        _ = try await client.lpush([string], into: key).get()
        logger.info("Enqueued message", metadata: [
            "senderID": .string(message.senderID.uuidString),
            "receiverID": .string(userID.uuidString)
        ])
    }

    func fetchAll(for userID: UUID) async throws -> [Message] {
        let key = RedisKey("queue:\(userID.uuidString)")
        let strings: [String?] = try await client.lrange(from: key, firstIndex: 0, lastIndex: -1, as: String.self).get()
        _ = try await client.delete([key]).get()
        logger.info("Fetched queued messages", metadata: ["userID": .string(userID.uuidString), "count": .string("\(strings.count)")])
        return try strings.compactMap { $0 }.map { str in
            let data = Data(str.utf8)
            return try decoder.decode(Message.self, from: data)
        }
    }
}
