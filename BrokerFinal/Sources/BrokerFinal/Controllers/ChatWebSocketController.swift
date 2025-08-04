import Vapor
import Logging

struct ChatWebSocketController: RouteCollection {
    let hub: WebSocketHub
    private let logger = Logger(label: "ChatWebSocketController")

    init(app: Application) {
        self.hub = WebSocketHub(queue: app.messageQueue, registry: app.locationRegistry, store: app.messageStore)
    }

    func boot(routes: any RoutesBuilder) throws {
        routes.webSocket("chat", ":userID", onUpgrade: connect)
    }

    func connect(req: Request, ws: WebSocket) {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            ws.close(promise: nil)
            return
        }
        logger.info("WebSocket connect", metadata: ["userID": .string(userID.uuidString)])
        ws.onClose.whenComplete { _ in
            logger.info("WebSocket closed", metadata: ["userID": .string(userID.uuidString)])
            Task { await hub.remove(userID: userID) }
        }
        Task { await hub.add(client: ws, for: userID) }
        ws.onText { ws, text in
            guard let data = text.data(using: .utf8),
                  let message = try? JSONDecoder().decode(Message.self, from: data) else {
                return
            }
            logger.info("Received text message", metadata: [
                "senderID": .string(message.senderID.uuidString),
                "receiverID": .string(message.receiverID.uuidString)
            ])
            Task { await hub.dispatch(message) }
        }

        ws.onBinary { ws, buffer in
            var dataBuffer = buffer
            guard let data = dataBuffer.readData(length: dataBuffer.readableBytes),
                  let message = try? JSONDecoder().decode(Message.self, from: data) else {
                return
            }
            logger.info("Received binary message", metadata: [
                "senderID": .string(message.senderID.uuidString),
                "receiverID": .string(message.receiverID.uuidString)
            ])
            Task { await hub.dispatch(message) }
        }
    }
}
