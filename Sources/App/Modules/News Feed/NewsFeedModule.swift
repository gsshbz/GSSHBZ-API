//
//  NewsFeedModule.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Vapor
import Fluent


struct NewsFeedModule: ModuleInterface {
    let router = NewsFeedRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(NewsFeedMigrations.v1())
        
        if app.environment == .development || app.environment == .testing {
            app.migrations.add(NewsFeedMigrations.seed())
        }
        
        app.middleware.use(ApiUserAuthenticator())
        
        try router.boot(routes: app.routes)
    }
}

