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
        validations.add("username", as: String.self, is: .alphanumeric && .count(4...))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}


// MARK: - Authentication requests
struct UserApiController {
    func signUpApi(_ req: Request) async throws -> HTTPStatus {
        try User.Account.Create.validate(content: req)
        
        let registerRequest = try req.content.decode(User.Account.Create.self)
        
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        
        let hashedPassword = try await req.password
            .async
            .hash(registerRequest.password)
        
        let user = UserAccountModel.create(from: registerRequest, hash: hashedPassword, registrationType: .manual)
        
        try await user.create(on: req.db)
        
//        try await req.emailVerifier.verify(for: user)
        
        return .created
    }
    
    func signInApi(_ req: Request) async throws -> User.Token.Detail {
        try User.Account.LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(User.Account.LoginRequest.self)
        
        let user = try await UserAccountModel.query(on: req.db)
            .filter(\.$email == loginRequest.email)
            .first()
        
        guard let user = user else { throw Abort(.notFound) }
        
        let successfulLogin = try await req.password.async.verify(loginRequest.password, created: user.password)
        
        if !successfulLogin {
            throw Abort(.unauthorized)
        }
        
        // Delete refresh token
        try await RefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try RefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
        try await refreshToken.create(on: req.db)
        
        let accessToken = try req.jwt.sign(JWTUser(with: user))
        let userDetail = try User.Account.Detail(id: user.requireID(), username: user.username)
        
        return User.Token.Detail(id: refreshToken.id!, user: userDetail, accessToken: accessToken, refreshToken: token)
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
        
        return try User.Account.Detail(id: user.requireID(), username: user.username)
    }
    
    func resetPasswordHandler(_ req: Request) async throws -> HTTPStatus {
        let resetPasswordRequest = try req.content.decode(User.Token.ResetPasswordRequest.self)
        
        guard let user = try await UserAccountModel.query(on: req.db).filter(\.$email == resetPasswordRequest.email).first() else {
            throw Abort(.noContent)
        }
        
        try await req.passwordResetter.reset(for: user)
        
        return .noContent
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
