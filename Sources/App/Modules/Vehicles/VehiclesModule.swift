//
//  VehiclesModule.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.09.2025..
//

import Vapor
import Fluent


struct VehiclesModule: ModuleInterface {
    let router = VehiclesRouter()
    
    func boot(_ app: Application) throws {
        app.migrations.add(VehicleMigrations.v1())
        
        if app.environment == .development || app.environment == .testing {
            app.migrations.add(VehicleMigrations.seed())
        }
        
        app.middleware.use(ApiUserAuthenticator())
        
        try router.boot(routes: app.routes)
    }
}

