import Foundation
import Vapor

/// Stores full conversation history between user pairs in memory.
actor MessageStore {
    private struct ConversationKey: Hashable {
        let a: UUID
        let b: UUID
        init(_ first: UUID, _ second: UUID) {
            if first.uuidString < second.uuidString {
                self.a = first
                self.b = second
            } else {
                self.a = second
                self.b = first
            }
        }
    }

    private var conversations: [ConversationKey: [Message]] = [:]

    func add(_ message: Message) {
        let key = ConversationKey(message.senderID, message.receiverID)
        conversations[key, default: []].append(message)
    }

    func history(between user1: UUID, and user2: UUID) -> [Message] {
        let key = ConversationKey(user1, user2)
        return conversations[key] ?? []
    }
}
