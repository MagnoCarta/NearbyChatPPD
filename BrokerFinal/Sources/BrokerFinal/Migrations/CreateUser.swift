import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("is_online", .bool, .required, .sql(.default(false)))
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
