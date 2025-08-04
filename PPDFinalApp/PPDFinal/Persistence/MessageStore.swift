import Foundation
import SwiftData

/// Simple SwiftData backed store for persisting chat history locally.
@MainActor
final class MessageStore {
    static let shared = MessageStore()
    let container: ModelContainer
    let context: ModelContext

    init(inMemory: Bool = false) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        container = try! ModelContainer(for: MessageData.self, configurations: configuration)
        context = ModelContext(container)
    }

    // MARK: - Operations
    func save(_ message: Message) {
        let record = MessageData(from: message)
        context.insert(record)
        try? context.save()
    }

    func fetchConversation(userID: UUID, contactID: UUID) -> [Message] {
        let predicate = #Predicate<MessageData> { data in
            (data.senderID == userID && data.receiverID == contactID) ||
            (data.senderID == contactID && data.receiverID == userID)
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let results = (try? context.fetch(descriptor)) ?? []
        return results.map { $0.toMessage() }.sorted { $0.timestamp < $1.timestamp }
    }
}
