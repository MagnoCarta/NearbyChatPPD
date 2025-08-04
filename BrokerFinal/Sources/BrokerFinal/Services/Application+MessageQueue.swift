import Vapor
import Redis

extension Application {
    private struct QueueKey: StorageKey {
        typealias Value = any MessageQueue
    }

    /// Shared message queue using Redis if available, otherwise an in-memory queue.
    var messageQueue: any MessageQueue {
        if let existing = self.storage[QueueKey.self] {
            return existing
        }
        let queue: any MessageQueue
        if Environment.get("REDIS_HOST") != nil {
            queue = RedisMessageQueue(client: self.redis)
        } else {
            queue = InMemoryMessageQueue()
        }
        self.storage[QueueKey.self] = queue
        return queue
    }
}
