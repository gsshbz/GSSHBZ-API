//
//  LeaseModule.swift
//
//
//  Created by Mico Miloloza on 13.06.2024..
//

import Vapor
import Fluent


struct LeaseModule: ModuleInterface {
    let router = LeaseRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(LeaseMigrations.v1())
        app.migrations.add(LeaseMigrations.seed())
        
        app.middleware.use(ApiUserAuthenticator())
        
        try router.boot(routes: app.routes)
    }
}
