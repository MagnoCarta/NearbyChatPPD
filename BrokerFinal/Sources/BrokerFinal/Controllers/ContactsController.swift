import Vapor
import Logging
import Fluent

struct ContactSyncBody: Content {
    let userID: UUID
    let location: Location
    let radius: Double
    let name: String?
}

struct ContactsController: RouteCollection {
    let registry: LocationRegistry
    let hub: WebSocketHub
    private let logger = Logger(label: "ContactsController")

    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("contacts")
        group.post("sync", use: sync)
    }

    func sync(req: Request) async throws -> [Contact] {
        let body = try req.content.decode(ContactSyncBody.self)
        logger.info("Sync contacts", metadata: [
            "userID": .string(body.userID.uuidString),
            "radius": .string("\(body.radius)")
        ])
        let resolvedName: String
        if let provided = body.name {
            resolvedName = provided
        } else if let user = try await UserModel.find(body.userID, on: req.db) {
            resolvedName = user.name
        } else if let existing = await registry.name(for: body.userID) {
            resolvedName = existing
        } else {
            logger.warning("Could not resolve name for user, defaulting to 'Unknown'", metadata: ["userID": .string(body.userID.uuidString)])
            resolvedName = "Unknown"
        }
        await registry.update(userID: body.userID, name: resolvedName, location: body.location, radius: body.radius)
        let contacts = await registry.allContacts()
        await hub.broadcastContacts()
        return contacts
    }
}
