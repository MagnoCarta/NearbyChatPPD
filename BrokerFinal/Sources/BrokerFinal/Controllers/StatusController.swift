import Vapor
import Logging

/// REST endpoints to update a user's status manually.
struct StatusController: RouteCollection {
    let registry: LocationRegistry
    let hub: WebSocketHub
    private let logger = Logger(label: "StatusController")

    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("status")
        group.put(":userID", use: update)
    }

    func update(req: Request) async throws -> HTTPStatus {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let status = try req.content.decode(UserStatus.self)
        logger.info("Status update", metadata: ["userID": .string(userID.uuidString), "status": .string(status.rawValue)])
        await registry.updateStatus(userID, status: status)
        await hub.broadcastContacts()
        return .ok
    }
}
