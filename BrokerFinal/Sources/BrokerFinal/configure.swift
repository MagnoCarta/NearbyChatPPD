import NIOSSL
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Vapor
import Redis

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let hostname = Environment.get("DATABASE_HOST") {
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: hostname,
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    } else {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    }

    // Configure Redis only if a host is provided
    if let redisHost = Environment.get("REDIS_HOST") {
        app.redis.configuration = try RedisConfiguration(
            hostname: redisHost,
            port: Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379
        )
    }

    app.migrations.add(CreateUser())
    app.migrations.add(CreateTodo())
    
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
