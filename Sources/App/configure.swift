import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Liquid
import LiquidLocalDriver
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // MARK: - JWKS
    if app.environment != .testing {
        let jwksFilePath = app.directory.workingDirectory + (Environment.get("JWKS_KEYPAIR_FILE") ?? "keypair.jwks")
        guard
            let jwks = FileManager.default.contents(atPath: jwksFilePath),
            let jwksString = String(data: jwks, encoding: .utf8) else {
            fatalError("Failed to load JWKS Keypair file at: \(jwksFilePath)")
        }
        
        try app.jwt.signers.use(jwksJSON: jwksString)
    }
    
    app.fileStorages.use(
        .local(
            publicUrl: "http://localhost:8080",
            publicPath: app.directory.publicDirectory,
            workDirectory: "assets"
        ),
        as: .local
    )
    app.routes.defaultMaxBodySize = "10mb"
    
    let sslContext = try NIOSSLContext(configuration: .clientDefault)
    let connectionConfig = PostgresConnection.Configuration.TLS.prefer(sslContext)
    app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,//SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "vapor",
        tls: .disable
    ), sqlLogLevel: .debug), as: .psql)
    
    
    // MARK: - Sessions
    app.sessions.use(.fluent)
    app.migrations.add(SessionRecord.migration)
    
    
    // MARK: - Middlewares
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    app.randomGenerators.use(.random)

    //MARK: - register routes
    let modules: [ModuleInterface] = [
        ArmoryModule(),
        UserModule(),
        LeaseModule()
    ]
    
    for module in modules {
        try module.boot(app)
    }
    
    try await app.autoMigrate()
}
