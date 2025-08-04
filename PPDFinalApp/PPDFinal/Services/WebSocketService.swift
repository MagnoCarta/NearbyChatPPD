import Foundation

@globalActor
actor WebSocketActor {
    static let shared = WebSocketActor()
}

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketServiceDidConnect(_ service: WebSocketService)
    func webSocketServiceDidDisconnect(_ service: WebSocketService, error: Error?)
    func webSocketService(_ service: WebSocketService, didReceive message: Message)
    func webSocketService(_ service: WebSocketService, didReceiveContacts contacts: [Contact])
}

extension WebSocketServiceDelegate {
    func webSocketServiceDidConnect(_ service: WebSocketService) {}
    func webSocketServiceDidDisconnect(_ service: WebSocketService, error: Error?) {}
    func webSocketService(_ service: WebSocketService, didReceive message: Message) {}
    func webSocketService(_ service: WebSocketService, didReceiveContacts contacts: [Contact]) {}
}

@WebSocketActor
final class WebSocketService {
    private let baseURL: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var isManuallyClosed = false
    private var currentUserID: UUID?

    private class DelegateWrapper {
        weak var delegate: WebSocketServiceDelegate?
        init(_ delegate: WebSocketServiceDelegate) { self.delegate = delegate }
    }

    private var delegates: [DelegateWrapper] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @MainActor
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func connect(userID: UUID) {
        isManuallyClosed = false
        currentUserID = userID
        let url = baseURL.appendingPathComponent(userID.uuidString)
        task = session.webSocketTask(with: url)
        task?.resume()
        print("WebSocket connecting to \(url)")
        notify { $0.webSocketServiceDidConnect(self) }
        listen()
    }

    func disconnect() {
        isManuallyClosed = true
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        notify { $0.webSocketServiceDidDisconnect(self, error: nil) }
        print("WebSocket disconnected manually")
    }

    func send(_ message: Message) {
        guard let task else { return }
        Task {
            do {
                let data = try encoder.encode(message)
                try await task.send(.data(data))
                print("WebSocket sent message \(message.id)")
            } catch {
                await handleError(error)
            }
        }
    }

    private func listen() {
        guard let task else { return }
        Task {
            while true {
                do {
                    let message = try await task.receive()
                    handle(message)
                    print("WebSocket received raw message")
                } catch {
                    await handleError(error)
                    break
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            if let contacts = try? decoder.decode([Contact].self, from: data) {
                notify { $0.webSocketService(self, didReceiveContacts: contacts) }
                print("Decoded contacts data: \(contacts.count)")
            } else if let decoded = try? decoder.decode(Message.self, from: data) {
                notify { $0.webSocketService(self, didReceive: decoded) }
                print("Decoded message data: \(decoded.id)")
            }
        case .string(let string):
            if let data = string.data(using: .utf8),
               let contacts = try? decoder.decode([Contact].self, from: data) {
                notify { $0.webSocketService(self, didReceiveContacts: contacts) }
                print("Decoded contacts string: \(contacts.count)")
            } else if let data = string.data(using: .utf8),
                      let decoded = try? decoder.decode(Message.self, from: data) {
                notify { $0.webSocketService(self, didReceive: decoded) }
                print("Decoded message string: \(decoded.id)")
            }
        @unknown default:
            break
        }
    }

    private func handleError(_ error: Error) async {
        notify { $0.webSocketServiceDidDisconnect(self, error: error) }
        print("WebSocket error: \(error)")
        await attemptReconnect()
    }

    private func attemptReconnect() async {
        guard !isManuallyClosed, let userID = currentUserID else { return }
        print("Attempting WebSocket reconnect")
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        connect(userID: userID)
    }

    func addDelegate(_ delegate: WebSocketServiceDelegate) {
        delegates.append(DelegateWrapper(delegate))
    }

    func removeDelegate(_ delegate: WebSocketServiceDelegate) {
        delegates.removeAll { $0.delegate === delegate || $0.delegate == nil }
    }

    private func notify(_ action: (WebSocketServiceDelegate) -> Void) {
        delegates = delegates.filter { $0.delegate != nil }
        for wrapper in delegates {
            if let delegate = wrapper.delegate {
                action(delegate)
            }
        }
    }
}
