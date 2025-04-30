import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Liquid
import LiquidLocalDriver
import JWT


// configures your application
public func configure(_ app: Application) async throws {
    switch app.environment {
        case .production:
        app.logger.logLevel = .info
        // Add production-specific configurations
        app.http.server.configuration.responseCompression = .enabled
        app.http.server.configuration.requestDecompression = .enabled
        
        // Protect against common web attacks
        app.middleware.use(SecurityHeadersMiddleware())
        
        case .development:
        app.logger.logLevel = .debug
        // Add development-specific configurations
        
        default:
        app.logger.logLevel = .debug
        }
    
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
//    let connectionConfig = PostgresConnection.Configuration.TLS.prefer(sslContext)
    app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5436,//SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "gsshbz_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "gsshbz_password",
        database: Environment.get("DATABASE_NAME") ?? "gsshbz_database",
        tls: .disable
    ), sqlLogLevel: app.environment == .production ? .info : .debug), as: .psql)
    
    // MARK: - Sessions
    app.sessions.use(.fluent)
    app.migrations.add(SessionRecord.migration)
    
    
    // MARK: - Middlewares
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(CustomErrorMiddleware())
    
    app.randomGenerators.use(.random)
    
    //MARK: - register routes
    let modules: [ModuleInterface] = [
        ArmoryModule(),
        UserModule(),
        LeaseModule(),
        NewsFeedModule()
    ]
    
    for module in modules {
        try module.boot(app)
    }
    
    try services(app)
    
    try await app.autoMigrate()
    
    // MARK: - WebSocket setup
    let eventLoop = app.eventLoopGroup.next()
    ArmoryWebSocketSystem.shared = ArmoryWebSocketSystem(eventLoop: eventLoop)
    
    app.webSocket("armory") { req, ws async in
        do {
            guard let clientIdString = req.query[String.self, at: "client"],
                  let clientId = UUID(uuidString: clientIdString),
                  let user = try await UserAccountModel.find(clientId, on: req.db) else {
                try await ws.close()
                return
            }
            
            ArmoryWebSocketSystem.shared.connect(try user.requireID(), ws)
            
            let leasesApi = UserLeasesApiController()
            let armoryApi = ArmoryItemsApiController()
            let newsApi = NewsFeedApiController()
            
            // Latest leases
            async let latestLeases = leasesApi.latestLeasesApi(req)
            // Latest items
            async let recentlyAddedItems = armoryApi.recentlyAddedItemsApi(req: req)
            // Latest news
            async let latestNews = newsApi.latestNewsApi(req: req)
            // Items in armory
            async let itemsInArmory = armoryApi.totalItemsApi(req: req)
            // Leased today
            async let leasedToday = leasesApi.leasedTodayApi(req: req)
            
            let dashboardData = Armory.Dashboard.Detail(
                latestLeases: try await latestLeases,
                recentlyAddedItems: try await recentlyAddedItems,
                latestNews: try await latestNews,
                itemsInArmory: try await itemsInArmory,
                leasedToday: try await leasedToday
            )
            
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .dashboard, dashboardData)
        } catch {
            print("Error handling WebSocket connection: \(error)")
            Task {
                try await ws.close()
            }
        }
    }
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    
    
    // Health check api
    app.get("health") { req -> HealthResponse in
        // Check database connection
        do {
            let rows = try await (req.db as! SQLDatabase).raw("SELECT 1 AS result").all(decoding: HealthCheckResult.self)
            guard let _ = rows.first else {
                throw Abort(.internalServerError, reason: "Database check failed")
            }
            
            // Add more health checks as needed
            return HealthResponse(status: "ok", version: "1.0.0", environment: app.environment.name)
        } catch {
            req.logger.error("Health check failed: \(error)")
            return HealthResponse(status: "error", version: "1.0.0", environment: app.environment.name)
        }
    }
    
    struct HealthCheckResult: Codable {
        let result: Int
    }
    
    // Health response model
    struct HealthResponse: Content {
        let status: String
        let version: String
        let environment: String
        let timestamp = Date()
    }
}
