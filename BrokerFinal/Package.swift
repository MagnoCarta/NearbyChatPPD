// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "BrokerFinal",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🗄 Fluent driver for SQLite for lightweight testing and development.
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.5.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 📦 Redis client for Vapor
        .package(url: "https://github.com/vapor/redis.git", from: "4.13.0"),
    ],
    targets: [
        .executableTarget(
            name: "BrokerFinal",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Redis", package: "redis"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "BrokerFinalTests",
            dependencies: [
                .target(name: "BrokerFinal"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
