import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Liquid
import LiquidLocalDriver
import JWT
import Redis
import QueuesRedisDriver
import SendGrid


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
        username: Environment.get("DATABASE_USERNAME") ?? "gsshbz_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "gsshbz_password",
        database: Environment.get("DATABASE_NAME") ?? "gsshbz_database",
        tls: .disable
    ), sqlLogLevel: .debug), as: .psql)
    
    // MARK: - Redis setup
    let redisHostname = Environment.get("REDIS_HOSTNAME") ?? "localhost"
    let redisConfiguration = try RedisConfiguration(hostname: redisHostname)
    
    app.redis.configuration = redisConfiguration
    app.sessions.use(.redis)
    
    // MARK: - Sessions
    app.sessions.use(.fluent)
    app.migrations.add(SessionRecord.migration)
    
    
    // MARK: - Middlewares
    // serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    
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
    
    try queues(app)
    try services(app)
    
    try await app.autoMigrate()
    
    
    // MARK: - Queues Job
    try app.queues.startInProcessJobs()
    
    
    // MARK: - Mail service setup
    app.sendgrid.initialize()
}
