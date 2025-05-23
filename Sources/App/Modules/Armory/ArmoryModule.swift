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
        
        if app.environment == .development || app.environment == .testing {
            app.migrations.add(ArmoryMigrations.seed())
        }
        
        app.middleware.use(UserSessionAuthenticator())
        
        try router.boot(routes: app.routes)
    }
}
