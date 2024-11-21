// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GSSHBZ",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/binarybirds/swift-html", from: "1.7.0"),
        .package(url: "https://github.com/binarybirds/liquid", from: "1.3.0"),
        .package(url: "https://github.com/binarybirds/liquid-local-driver", from: "1.3.0"),
        .package(url: "https://github.com/vapor-community/Imperial.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor-community/sendgrid.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0-rc.1"),
        
        // Other
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "SwiftHtml", package: "swift-html"),
                .product(name: "SwiftSvg", package: "swift-html"),
                .product(name: "Liquid", package: "liquid"),
                .product(name: "LiquidLocalDriver", package: "liquid-local-driver"),
                .product(name: "ImperialGoogle", package: "Imperial"),
                .product(name: "SendGrid", package: "sendgrid"),
                .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://www.swift.org/server/guides/building.html#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),

            // Workaround for https://github.com/apple/swift-package-manager/issues/6940
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "Fluent"),
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        ])
    ]
)
