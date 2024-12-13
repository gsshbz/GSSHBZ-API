//
//  UserApiController.swift
//
//
//  Created by Mico Miloloza on 09.02.2024..
//

import Vapor
import Fluent


extension User.Token.Detail: Content {}
extension User.Token.AccessTokenRequest: Content {}
extension User.Token.AccessTokenResponse: Content {}
extension User.Account.Create: Content {}
extension User.Account.LoginRequest: Content {}
extension User.Account.List: Content {}
extension User.Account.Detail: Content {}

extension User.Account.LoginRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}

extension User.Account.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: .ascii)
        validations.add("lastName", as: String.self, is: .ascii)
//        validations.add("username", as: String.self, is: .alphanumeric && .count(4...))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}


// MARK: - Authentication requests
struct UserApiController {
    func signUpApi(_ req: Request) async throws -> User.Token.Detail {
        try User.Account.Create.validate(content: req)
        
        let registerRequest = try req.content.decode(User.Account.Create.self)
        
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        
        let hashedPassword = try await req.password
            .async
            .hash(registerRequest.password)
        
        let user = try await UserAccountModel.create(from: registerRequest, req: req, hash: hashedPassword, registrationType: .manual)
        
        try await user.create(on: req.db)
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try RefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
        // Save the refresh token to the database
        try await refreshToken.create(on: req.db)
        
        // Generate an access token (JWT)
        let accessToken = try req.jwt.sign(JWTUser(with: user))
        
        // Build user details for the response
        let userDetail = try User.Account.Detail(
            id: user.requireID(),
            firstName: user.firstName,
            lastName: user.lastName,
            imageKey: user.imageKey,
            email: user.email,
            isAdmin: user.isAdmin
        )
        
        // Return the token details
        return User.Token.Detail(
            id: refreshToken.id!,
            user: userDetail,
            accessToken: accessToken,
            refreshToken: token
        )
    }
    
    func signInApi(_ req: Request) async throws -> User.Token.Detail {
        try User.Account.LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(User.Account.LoginRequest.self)
        
        let user = try await UserAccountModel.query(on: req.db)
            .filter(\.$email == loginRequest.email)
            .first()
        
        guard let user = user else { throw AuthenticationError.userNotFound }
        
        let successfulLogin = try await req.password.async.verify(loginRequest.password, created: user.password)
        
        if !successfulLogin {
            throw AuthenticationError.invalidEmailOrPassword
        }
        
        // Delete refresh token
        try await RefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try RefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
        try await refreshToken.create(on: req.db)
        
        let accessToken = try req.jwt.sign(JWTUser(with: user))
        let userDetail = try User.Account.Detail(id: user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey, email: user.email, isAdmin: user.isAdmin)
        
        return User.Token.Detail(id: refreshToken.id!, user: userDetail, accessToken: accessToken, refreshToken: token)
    }
    
    func signOutApi(_ req: Request) async throws -> HTTPStatus {
        // Require the user to be authenticated
        let jwtUser = try req.auth.require(JWTUser.self)
        
        // Find and delete all refresh tokens for this user, essentially signing them out
        try await RefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == jwtUser.userId)
            .delete()
        
        // Optionally, if you want to perform other cleanup tasks, like logging out on the frontend.
        
        return .ok
    }
    
    func refreshAccessTokenHandler(_ req: Request) async throws -> User.Token.AccessTokenResponse {
        let accessTokenRequest = try req.content.decode(User.Token.AccessTokenRequest.self)
        let hashedRefreshToken = SHA256.hash(accessTokenRequest.refreshToken)
        
        let oldRefreshToken = try await RefreshTokenModel.query(on: req.db)
            .filter(\.$token == hashedRefreshToken)
            .first()
        
        guard let oldRefreshToken = oldRefreshToken else {
            throw AuthenticationError.refreshTokenOrUserNotFound
        }
        
        try await oldRefreshToken.delete(on: req.db)
        
        guard oldRefreshToken.expiresAt > Date() else {
            throw AuthenticationError.refreshTokenHasExpired
        }
        
        // TODO: - Checked if the user is fetched properly
        guard let user = try await UserAccountModel.find(oldRefreshToken.$user.id, on: req.db) else {
            throw AuthenticationError.refreshTokenOrUserNotFound
        }
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try RefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        let payloadUser = try JWTUser(with: user)
        let accessToken = try req.jwt.sign(payloadUser)
        
        try await refreshToken.create(on: req.db)
        
        return User.Token.AccessTokenResponse(refreshToken: token, accessToken: accessToken)
    }
    
    func getCurrentUserHandler(_ req: Request) async throws -> User.Account.Detail {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        return try User.Account.Detail(id: user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey, email: user.email, isAdmin: user.isAdmin)
    }
    
    func updateUserApi(_ req: Request) async throws -> User.Account.Detail {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        let patchUser = try req.content.decode(User.Account.Patch.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
//        var shouldUpdateImage: Bool = false
//        var publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/default-avatar.jpg"
//        
//        if let image = patchUser.image {
//            // Validate MIME type
//            guard ["image/jpeg", "image/png"].contains(image.contentType?.description) else {
//                throw Abort(.unsupportedMediaType, reason: "Only JPEG and PNG images are allowed.")
//            }
//            
//            shouldUpdateImage = true
//            // Get the `Public` directory path
//            let assetsDirectory = req.application.directory.publicDirectory + "img/"
//            
//            // Generate a unique file name for the image
//            let fileExtension = image.filename.split(separator: ".").last ?? "jpg"
//            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
//            
//            // Full path where the image will be saved
//            let filePath = assetsDirectory + uniqueFileName
//            
//            // Save the image data to the specified path
//            try await req.fileio.writeFile(image.data, at: filePath)
//            
//            shouldUpdateImage = true
//            publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/\(uniqueFileName)"
//        }
        
        user.isAdmin = patchUser.isAdmin ?? user.isAdmin
        user.firstName = patchUser.firstName ?? user.firstName
        user.lastName = patchUser.lastName ?? user.lastName
        user.email = patchUser.email ?? user.email
        user.phoneNumber = patchUser.phoneNumber ?? user.phoneNumber
        user.address = patchUser.address ?? user.address
        user.imageKey = /*shouldUpdateImage ? publicImageUrl : */patchUser.imageKey ?? user.imageKey
        
        try await user.update(on: req.db)
        
        let userDetails = User.Account.Detail(id: try user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey, email: user.email, isAdmin: user.isAdmin)
        
        return userDetails
    }
    
    func resetPasswordHandler(_ req: Request) async throws -> HTTPStatus {
        let resetPasswordRequest = try req.content.decode(User.Token.ResetPasswordRequest.self)
        
        guard let user = try await UserAccountModel.query(on: req.db).filter(\.$email == resetPasswordRequest.email).first() else {
            throw Abort(.noContent)
        }
        
        try await req.passwordResetter.reset(for: user)
        
        return .ok
    }
    
    func verifyResetPasswordTokenHandler(_ req: Request) async throws -> HTTPStatus {
        let token = try req.query.get(String.self, at: "token")
        let hashedToken = SHA256.hash(token)
        
        guard let passwordToken = try await req.passwordTokens.find(token: hashedToken) else {
            throw AuthenticationError.invalidPasswordToken
        }
        
        
        guard passwordToken.expiresAt > Date() else {
            try await req.passwordTokens.delete(passwordToken)
            throw AuthenticationError.passwordTokenHasExpired
        }
        
        return .noContent
    }
}
