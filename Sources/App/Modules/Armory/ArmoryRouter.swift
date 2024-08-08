//
//  ArmoryRouter.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Vapor


public struct ArmoryRouter: RouteCollection {
    let armoryCategoryApiController = ArmoryCategoryApiController()
    let armoryItemsController = ArmoryItemsApiController()
//    let armoryLeasesController = UserLeasesApiController()
    
    
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let apiAuthenticationRoutes = routes.grouped("api", "auth")
        
        let authenticatorRoutes = routes
            .grouped(UserCredentialsAuthenticator())
        let authenticated = apiAuthenticationRoutes
            .grouped(ApiUserAuthenticator())
            .grouped(JWTUser.guardMiddleware())
        
        armoryCategoryApiController.setupRoutes(api)
        armoryItemsController.setupRoutes(api)
//        armoryLeasesController.setupRoutes(authenticated)
        
//        api.on(.POST, ["armory", "accessories"], use: armoryAccessoryController.leaseAccessories)
    }
}
