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
        let resetPassword = apiRoutes.grouped("reset-password")
        
        apiRoutes
//            .grouped(JWTUser.guardMiddleware())
            .on(.POST, "sign-in", use: apiController.signInApi)
        
        apiRoutes.on(.POST, "sign-out", use: apiController.signOutApi)
        
        apiRoutes.on(.POST, "sign-up", use: apiController.signUpApi)
        
        apiRoutes.on(.POST, "refresh-access-token", use: apiController.refreshAccessTokenHandler)
        
        apiRoutes.on(.GET, "current-user", use: apiController.getCurrentUserHandler)
        
        apiRoutes.on(.POST, "user", use: apiController.updateUserApi)
        
        apiRoutes.on(.GET, "user", ":userId", use: apiController.getUserApi)
                
        apiRoutes.on(.GET, "users", use: apiController.searchUsersApi)
        
        apiRoutes.on(.GET, "generate-registration-token", use: apiController.createRegistrationTokenApi)
        
        apiRoutes.on(.GET, "generate-reset-password-token", use: apiController.createResetPasswordTokenApi)
        
        apiRoutes.on(.POST, "reset-password", use: apiController.resetPasswordApi)
        
//        resetPassword.on(.POST, use: apiController.resetPasswordHandler)
//        resetPassword.on(.GET, "verify", use: apiController.verifyResetPasswordTokenHandler)
    }
}
