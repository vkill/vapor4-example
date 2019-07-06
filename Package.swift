// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Vapor4Example",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-alpha.1.5"),
        .package(url: "https://github.com/vapor/fluent-kit.git", from: "1.0.0-alpha.1.3"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-alpha.1.2"),
        .package(url: "https://github.com/vapor/redis-kit.git", from: "1.0.0-alpha.1.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0-alpha.1"),
        .package(url: "https://github.com/dduan/TOMLDecoder", from: "0.1.3"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            "Vapor",
            "FluentKit", "FluentPostgresDriver",
            "RedisKit",
            "JWTKit",
            "TOMLDecoder",
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
        .testTarget(name: "AppFutureTests", dependencies: ["App", "TOMLDecoder"])
    ]
)
