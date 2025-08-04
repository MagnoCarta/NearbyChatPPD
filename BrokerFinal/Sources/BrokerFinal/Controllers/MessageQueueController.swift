import Vapor
import Logging

/// REST endpoints for retrieving queued offline messages.
struct MessageQueueController: RouteCollection {
    private let logger = Logger(label: "MessageQueueController")
    func boot(routes: any RoutesBuilder) throws {
        let queueRoutes = routes.grouped("queue")
        queueRoutes.get(":userID", use: fetch)
    }

    func fetch(req: Request) async throws -> [Message] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        logger.info("Fetch queued messages", metadata: ["userID": .string(userID.uuidString)])
        return try await req.application.messageQueue.fetchAll(for: userID)
    }
}
