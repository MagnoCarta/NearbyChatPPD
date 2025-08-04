import Foundation
import Vapor

/// Common interface for message queue implementations.
protocol MessageQueue: Sendable {
    func enqueue(_ message: Message, for userID: UUID) async throws
    func fetchAll(for userID: UUID) async throws -> [Message]
}

/// In-memory message queue used for testing or when Redis is unavailable.
actor InMemoryMessageQueue: MessageQueue {
    private var storage: [UUID: [Message]] = [:]

    func enqueue(_ message: Message, for userID: UUID) async throws {
        storage[userID, default: []].append(message)
    }

    func fetchAll(for userID: UUID) async throws -> [Message] {
        let messages = storage[userID] ?? []
        storage[userID] = nil
        return messages
    }
}
