import Vapor

extension Application {
    private struct MessageStoreKey: StorageKey {
        typealias Value = MessageStore
    }

    var messageStore: MessageStore {
        if let existing = self.storage[MessageStoreKey.self] {
            return existing
        }
        let store = MessageStore()
        self.storage[MessageStoreKey.self] = store
        return store
    }
}
