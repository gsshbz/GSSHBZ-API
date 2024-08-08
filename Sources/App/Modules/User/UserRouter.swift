//
//  UserRouter.swift
//  
//
//  Created by Mico Miloloza on 28.06.2023..
//

import Vapor
import JWT


struct UserRouter: RouteCollection {
    let apiController = UserApiController()
    
    func boot(routes: RoutesBuilder) throws {
        let apiRoutes = routes.grouped("api")
        
        apiRoutes
//            .grouped(JWTUser.guardMiddleware())
            .on(.POST, "sign-in", use: apiController.signInApi)
        
        apiRoutes.on(.POST, "sign-up", use: apiController.signUpApi)
        
        apiRoutes.on(.POST, "refresh-access-token", use: apiController.refreshAccessTokenHandler)
    }
}
