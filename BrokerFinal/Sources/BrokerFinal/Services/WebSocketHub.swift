import Vapor
import Foundation
import Logging

actor WebSocketHub {
    private var clients: [UUID: WebSocket] = [:]
    private let encoder = JSONEncoder()
    private let queue: any MessageQueue
    private let registry: LocationRegistry
    private let store: MessageStore
    private let logger = Logger(label: "WebSocketHub")

    init(queue: any MessageQueue, registry: LocationRegistry, store: MessageStore) {
        self.queue = queue
        self.registry = registry
        self.store = store
    }

    func add(client ws: WebSocket, for userID: UUID) async {
        clients[userID] = ws
        await registry.setOnline(userID, isOnline: true)
        logger.info("WebSocket connected", metadata: ["userID": .string(userID.uuidString)])
        await broadcastContacts()
    }

    func remove(userID: UUID) async {
        clients.removeValue(forKey: userID)
        await registry.setOnline(userID, isOnline: false)
        logger.info("WebSocket disconnected", metadata: ["userID": .string(userID.uuidString)])
        await broadcastContacts()
    }

    func dispatch(_ message: Message) async {
        await store.add(message)
        if let ws = clients[message.receiverID] {
            if let data = try? encoder.encode(message) {
                var buffer = ByteBufferAllocator().buffer(capacity: data.count)
                buffer.writeBytes(data)
                if let addedData = buffer.readData(length: buffer.readableBytes) {
                    try? await ws.send(raw: addedData, opcode: .binary)
                } else {
                    logger.warning("Failed to read data from ByteBuffer")
                }
            }
        } else {
            try? await queue.enqueue(message, for: message.receiverID)
            logger.info("Queued message for offline user", metadata: [
                "senderID": .string(message.senderID.uuidString),
                "receiverID": .string(message.receiverID.uuidString)
            ])
        }
        logger.info("Dispatched message", metadata: [
            "senderID": .string(message.senderID.uuidString),
            "receiverID": .string(message.receiverID.uuidString)
        ])
    }

    func sendContacts(_ contacts: [Contact], to userID: UUID) async {
        guard let ws = clients[userID], let data = try? encoder.encode(contacts) else { return }
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        if let addedData = buffer.readData(length: buffer.readableBytes) {
            try? await ws.send(raw: addedData, opcode: .binary)
        }
        logger.info("Sent contacts list", metadata: ["userID": .string(userID.uuidString), "count": .string("\(contacts.count)")])
    }

    func broadcastContacts() async {
        let contacts = await registry.allContacts()
        guard let data = try? encoder.encode(contacts) else { return }
        for (userID, ws) in clients {
            var buffer = ByteBufferAllocator().buffer(capacity: data.count)
            buffer.writeBytes(data)
            if let sendData = buffer.readData(length: buffer.readableBytes) {
                try? await ws.send(raw: sendData, opcode: .binary)
            }
            logger.info("Broadcasted contacts", metadata: ["userID": .string(userID.uuidString), "count": .string("\(contacts.count)")])
        }
    }
}
