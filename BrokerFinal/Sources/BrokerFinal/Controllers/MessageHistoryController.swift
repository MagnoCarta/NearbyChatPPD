import Vapor
import Logging

/// REST endpoints for retrieving complete conversation history.
struct MessageHistoryController: RouteCollection {
    let store: MessageStore
    private let logger = Logger(label: "MessageHistoryController")

    func boot(routes: any RoutesBuilder) throws {
        let historyRoutes = routes.grouped("messages")
        historyRoutes.get(":user1ID", ":user2ID", use: history)
    }

    func history(req: Request) async throws -> [Message] {
        guard let user1 = req.parameters.get("user1ID", as: UUID.self),
              let user2 = req.parameters.get("user2ID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        logger.info("Fetch conversation history", metadata: [
            "user1ID": .string(user1.uuidString),
            "user2ID": .string(user2.uuidString)
        ])
        return await store.history(between: user1, and: user2)
    }
}
