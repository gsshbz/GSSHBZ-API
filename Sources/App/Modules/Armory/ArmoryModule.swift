//
//  ArmoryModule.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Vapor


struct ArmoryModule: ModuleInterface {
    let router = ArmoryRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(ArmoryMigrations.v1())
        app.migrations.add(ArmoryMigrations.seed())
        
        app.middleware.use(UserSessionAuthenticator())
        app.databases.middleware.use(ArmoryItemModelUpdateMiddleware(), on: .psql)
        
        try router.boot(routes: app.routes)
    }
}
