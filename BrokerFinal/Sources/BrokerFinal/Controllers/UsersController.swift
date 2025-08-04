import Vapor
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("users")
        group.post("register", ":name", use: register)
        group.post("login", ":name", use: login)
    }

    @Sendable
    func register(req: Request) async throws -> UserDTO {
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest)
        }
        let location = try req.content.decode(Location.self)
        if try await UserModel.query(on: req.db).filter(\.$name == name).first() != nil {
            throw Abort(.conflict)
        }
        let user = UserModel(name: name, latitude: location.latitude, longitude: location.longitude, isOnline: true)
        try await user.save(on: req.db)
        let userID = try user.requireID()
        await req.application.locationRegistry.update(userID: userID, name: user.name, location: location, radius: 1000)
        return try UserDTO(id: userID, name: user.name, location: location, status: .online)
    }

    @Sendable
    func login(req: Request) async throws -> UserDTO {
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest)
        }
        let location = try req.content.decode(Location.self)
        if let user = try await UserModel.query(on: req.db).filter(\.$name == name).first() {
            user.latitude = location.latitude
            user.longitude = location.longitude
            user.isOnline = true
            try await user.save(on: req.db)
            let userID = try user.requireID()
            await req.application.locationRegistry.update(userID: userID, name: user.name, location: location, radius: 1000)
            return try UserDTO(id: userID, name: user.name, location: location, status: .online)
        } else {
            throw Abort(.notFound)
        }
    }
}
