import Foundation

/// View model that binds a ``WebSocketService`` to the chat UI and handles
/// sending and receiving ``Message`` objects over the live WebSocket connection.
@Observable
@MainActor
final class ChatViewModel {
    private let webSocketService: WebSocketService
    private let apiClient: APIClient
    private let store: MessageStore

    /// All chat messages currently displayed.
    var messages: [Message] = []
    /// Text of the message being composed.
    var draft: String = ""
    /// Indicates if the WebSocket connection is active.
    var isConnected: Bool = false

    init(webSocketService: WebSocketService? = nil, apiClient: APIClient? = nil, messageStore: MessageStore? = nil) {
        // Use explicit IPv4 loopback to match the local Vapor server
        self.webSocketService = webSocketService ?? WebSocketService(baseURL: URL(string: "ws://127.0.0.1:8080/chat")!)
        self.apiClient = apiClient ?? APIClient(baseURL: URL(string: "http://127.0.0.1:8080")!)
        self.store = messageStore ?? MessageStore.shared
        Task { @WebSocketActor in
            self.webSocketService.addDelegate(self)
        }
    }

    /// Connects to the WebSocket server.
    @WebSocketActor
    func connect(userID: UUID) {
        webSocketService.connect(userID: userID)
        print("Connecting WebSocket for user: \(userID)")
    }

    /// Disconnects from the WebSocket server.
    @WebSocketActor
    func disconnect() {
        webSocketService.disconnect()
        print("Disconnecting WebSocket")
    }

    /// Sends the current draft as a ``Message`` to the receiver.
    func sendMessage(from senderID: UUID, to receiverID: UUID) {
        let newMessage = Message(senderID: senderID,
                                 receiverID: receiverID,
                                 content: draft)
        messages.append(newMessage)
        store.save(newMessage)
        draft = ""
        print("Sending message: \(newMessage.content)")
        Task { @WebSocketActor in
            webSocketService.send(newMessage)
        }
    }

    /// Fetches the full conversation history between the user and contact from the server.
    @APIActor
    func fetchHistory(userID: UUID, contactID: UUID) async {
        do {
            let history = try await apiClient.fetchMessageHistory(between: userID, and: contactID)
            await MainActor.run {
                self.messages = history.sorted { $0.timestamp < $1.timestamp }
                history.forEach { self.store.save($0) }
            }
        } catch {
            print("Failed to fetch history: \(error)")
        }
    }

    /// Fetches queued offline messages for the given user and appends them to the chat history.
    @APIActor
    func fetchQueuedMessages(for userID: UUID, contactID: UUID) async {
        do {
            let fetched = try await apiClient.fetchQueuedMessages(for: userID)
            let relevant = fetched.filter { $0.senderID == contactID || $0.receiverID == contactID }
            await MainActor.run {
                self.messages.append(contentsOf: relevant)
                relevant.forEach { self.store.save($0) }
            }
        } catch {
            // For demo purposes simply print the error
            print("Failed to fetch queued messages: \(error)")
        }
    }

    /// Appends an incoming message to the conversation.
    func append(_ message: Message) {
        messages.append(message)
        store.save(message)
        print("Received message from \(message.senderID)")
    }

    /// Loads persisted conversation with the given contact from disk.
    func loadConversation(userID: UUID, contactID: UUID) {
        messages = store.fetchConversation(userID: userID, contactID: contactID)
        print("Loaded conversation with \(contactID)")
    }
}

// MARK: - WebSocketServiceDelegate

extension ChatViewModel: WebSocketServiceDelegate {
    nonisolated func webSocketServiceDidConnect(_ service: WebSocketService) {
        Task { @MainActor in
            self.isConnected = true
            print("WebSocket connected")
        }
    }

    nonisolated func webSocketServiceDidDisconnect(_ service: WebSocketService, error: Error?) {
        Task { @MainActor in
            self.isConnected = false
            print("WebSocket disconnected")
        }
    }

    nonisolated func webSocketService(_ service: WebSocketService, didReceive message: Message) {
        Task { @MainActor in
            self.append(message)
            print("WebSocket received message from \(message.senderID)")
        }
    }
}
