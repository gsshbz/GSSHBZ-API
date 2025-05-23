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
extension User.Token.RegistrationToken: Content {}
extension User.Token.ResetPasswordToken: Content {}
extension User.Account.Create: Content {}
extension User.Account.LoginRequest: Content {}
extension User.Account.List: Content {}
extension User.Account.Detail: Content {}
extension User.Account.Public: Content {}

extension User.Account.LoginRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}

extension User.Account.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: .ascii && !.empty)
        validations.add("lastName", as: String.self, is: .ascii && !.empty)
        validations.add("email", as: String.self, is: .email && !.empty)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("registrationToken", as: String.self, is: !.empty)
    }
}


// MARK: - Authentication requests
struct UserApiController: ListController {
    typealias ApiModel = User.Account
    typealias DatabaseModel = UserAccountModel
    
    func signUpApi(_ req: Request) async throws -> User.Token.Detail {
        let fieldToErrorIdentifier: [String: String] = [
            "email": "invalid_email",
            "password": "invalid_password",
            "registrationToken": "missing_registration_token",
            "firstName": "invalid_first_name",
            "lastName": "invalid_last_name"
            // Add other mappings as needed
        ]
        
        let fieldToErrorDetails: [String: (identifier: String, reason: String, status: HTTPResponseStatus)] = [
            "email": ("invalid_email", "Email is invalid", .badRequest),
            "password": ("invalid_password", "Password must be at least 8 characters", .badRequest),
            "registrationToken": ("missing_registration_token", "Registration token is required", .badRequest),
            "firstName": ("invalid_first_name", "First name is required", .badRequest),
            "lastName": ("invalid_last_name", "Last name is required", .badRequest)
        ]
        
        do {
            try User.Account.Create.validate(content: req)
        } catch let error as ValidationsError {
            // Convert Vapor's validation error to your custom error
            //            let failedFields = error.failures.map { $0.key }
            
            // Map validation failures to field+identifier pairs
            let failures = error.failures.map { failure -> (field: String, identifier: String) in
                let field = failure.key.stringValue
                // Use the mapping if available, otherwise generate a default identifier
                let identifier = fieldToErrorIdentifier[field] ?? "invalid_\(field)"
                return (field: field, identifier: identifier)
            }
            
            if failures.count > 1 {
                throw AuthenticationError.multipleValidationFailures(failures)
            } else if let failure = failures.first, let errorDetails = fieldToErrorDetails[failure.field] {
                throw AuthenticationError.specificError(
                    identifier: errorDetails.identifier,
                    reason: errorDetails.reason,
                    status: errorDetails.status
                )
            } else if let failure = failures.first {
                throw AuthenticationError.invalidField(failure.field)
            } else {
                throw AuthenticationError.invalidField("unknown")
            }
        }
        
        let registerRequest = try req.content.decode(User.Account.Create.self)
        
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        
        // Check if the email already exists before attempting to create the user
        if let _ = try await UserAccountModel.query(on: req.db)
            .filter(\.$email == registerRequest.email)
            .first() {
            throw AuthenticationError.emailAlreadyExists
        }
        
        // Verify registration code
        guard let registrationToken = try await UserRegistrationTokenModel.query(on: req.db)
            .filter(\.$code == registerRequest.registrationToken)
            .filter(\.$isUsed == false)
            .first() else {
            throw AuthenticationError.registrationTokenNotValid
        }
        
        guard registrationToken.expiresAt > Date() else {
            try await UserRegistrationTokenModel.query(on: req.db)
                .filter(\.$id == registrationToken.requireID())
                .delete()
            throw AuthenticationError.registrationTokenHasExpired
        }
        
        let hashedPassword = try await req.password
            .async
            .hash(registerRequest.password)
        
        let user = try await UserAccountModel.create(from: registerRequest, req: req, hash: hashedPassword, registrationType: .manual)
        
        // Use a transaction to ensure both operations succeed or fail together
        try await req.db.transaction { database in
            try await user.create(on: database)
            
            // Mark the registration token as used
            registrationToken.isUsed = true
            try await registrationToken.save(on: database)
        }
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try UserRefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
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
        try await UserRefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try UserRefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
        try await refreshToken.create(on: req.db)
        
        let accessToken = try req.jwt.sign(JWTUser(with: user))
        let userDetail = try User.Account.Detail(id: user.requireID(), firstName: user.firstName, lastName: user.lastName, imageKey: user.imageKey, email: user.email, isAdmin: user.isAdmin)
        
        return User.Token.Detail(id: refreshToken.id!, user: userDetail, accessToken: accessToken, refreshToken: token)
    }
    
    func signOutApi(_ req: Request) async throws -> HTTPStatus {
        // Require the user to be authenticated
        let jwtUser = try req.auth.require(JWTUser.self)
        
        // Find and delete all refresh tokens for this user, essentially signing them out
        try await UserRefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == jwtUser.userId)
            .delete()
        // Optionally, we might want want to perform other cleanup tasks, like logging out on the frontend.
        
        return .ok
    }
    
    func refreshAccessTokenHandler(_ req: Request) async throws -> User.Token.AccessTokenResponse {
        let accessTokenRequest = try req.content.decode(User.Token.AccessTokenRequest.self)
        let hashedRefreshToken = SHA256.hash(accessTokenRequest.refreshToken)
        
        let oldRefreshToken = try await UserRefreshTokenModel.query(on: req.db)
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
        let refreshToken = try UserRefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        let payloadUser = try JWTUser(with: user)
        let accessToken = try req.jwt.sign(payloadUser)
        
        try await refreshToken.create(on: req.db)
        
        return User.Token.AccessTokenResponse(refreshToken: token, accessToken: accessToken)
    }
    
    func getUserApi(_ req: Request) async throws -> User.Account.Public {
        guard let userIdString = req.parameters.get("userId"), let userId = UUID(uuidString: userIdString) else { throw AuthenticationError.userNotFound }
        
        guard let user = try await UserAccountModel.find(userId, on: req.db) else { throw AuthenticationError.userNotFound }
        
        let userPublic = User.Account.Public(
            id: try user.requireID(),
            firstName: user.firstName,
            lastName: user.lastName,
            imageKey: user.imageKey
        )
        
        return userPublic
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
        
        guard user.isAdmin else { throw ArmoryErrors.unauthorizedAccess }
        
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
    
    func searchUsersApi(_ req: Request) async throws -> User.Account.List {
        let searchQuery = req.query[String.self, at: "search"]?.lowercased()
        
        // Use paginatedList with queryBuilders to apply filters
        let models = try await paginatedList(req) { query in
            if let searchQuery = searchQuery, !searchQuery.isEmpty {
                query.group(.or) { or in
                    or.filter(\.$firstName, .custom("ilike"), "%\(searchQuery)%")
                    or.filter(\.$lastName, .custom("ilike"), "%\(searchQuery)%")
                    or.filter(\.$email, .custom("ilike"), "%\(searchQuery)%")
                }
            }
        }
        
        // Map models to response
        let userList = try models.items.map { user in
            User.Account.Public(
                id: try user.requireID(),
                firstName: user.firstName,
                lastName: user.lastName,
                imageKey: user.imageKey
            )
        }
        
        return User.Account.List(
            users: userList,
            metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total)
        )
    }
    
    func resetPasswordApi(_ req: Request) async throws -> User.Token.Detail {
        let resetPasswordRequest = try req.content.decode(User.Token.ResetPasswordRequest.self)
        
        // Ensure passwords match
        guard resetPasswordRequest.newPassword == resetPasswordRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        
        guard let user = try await UserAccountModel.query(on: req.db).filter(\.$email == resetPasswordRequest.email).first() else {
            throw AuthenticationError.userNotFound
        }
        
        let userId = try user.requireID()
        
        // Find the password reset token
        guard let resetPasswordToken = try await UserResetPasswordTokenModel.query(on: req.db)
            .filter(\.$token == resetPasswordRequest.token)
            .filter(\.$isUsed == false)
            .filter(\.$user.$id == userId)
            .first() else {
            throw AuthenticationError.invalidPasswordToken
        }
        
        // Check if the token has expired
        guard resetPasswordToken.expiresAt > Date() else {
            throw AuthenticationError.passwordTokenHasExpired
        }
        
        let hashedPassword = try await req.password
            .async
            .hash(resetPasswordRequest.newPassword)
        
        user.password = hashedPassword
        
        // Use a transaction to ensure both operations succeed or fail together
        try await req.db.transaction { database in
            try await user.update(on: database)
            
            // Mark the reset password token as used
            resetPasswordToken.isUsed = true
            try await resetPasswordToken.save(on: database)
        }
        
        // Delete old refresh token
        try await UserRefreshTokenModel.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        
        let token = req.random.generate(bits: 256)
        let refreshToken = try UserRefreshTokenModel(token: SHA256.hash(token), userId: user.requireID())
        
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
    
    func createRegistrationTokenApi(_ req: Request) async throws -> User.Token.RegistrationToken {
        // Ensure only admins can create codes
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        guard user.isAdmin else { throw ArmoryErrors.unauthorizedAccess }
        
        // Generate and verify uniqueness of a 6-character token
        var token: String
        var isUnique = false
        
        repeat {
            // Generate a random 6-character token
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            var tokenChars = [Character]()
            
            for _ in 0..<6 {
                let randomInt = Int.random(in: 0..<characters.count)
                let index = characters.index(characters.startIndex, offsetBy: randomInt)
                tokenChars.append(characters[index])
            }
            
            token = String(tokenChars)
            
            // Check if token already exists
            let existingToken = try await UserRegistrationTokenModel.query(on: req.db)
                .filter(\.$code == token)
                .first()
            
            isUnique = existingToken == nil
        } while !isUnique
        
        let tokenModel = UserRegistrationTokenModel(code: token)
        try await tokenModel.create(on: req.db)
        
        return .init(id: try tokenModel.requireID(), token: tokenModel.code, isUsed: tokenModel.isUsed, createdAt: tokenModel.createdAt)
    }
    
    func createResetPasswordTokenApi(_ req: Request) async throws -> User.Token.ResetPasswordToken {
        // Ensure only admins can create codes
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        guard user.isAdmin else { throw ArmoryErrors.unauthorizedAccess }
        
        guard let userId = req.query[UUID.self, at: "id"] else {
            throw ArmoryErrors.unknownError
        }
        // Generate and verify uniqueness of a 6-character token
        var token: String
        var isUnique = false
        
        repeat {
            // Generate a random 6-character token
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            var tokenChars = [Character]()
            
            for _ in 0..<6 {
                let randomInt = Int.random(in: 0..<characters.count)
                let index = characters.index(characters.startIndex, offsetBy: randomInt)
                tokenChars.append(characters[index])
            }
            
            token = String(tokenChars)
            
            // Check if token already exists
            do {
                let existingToken = try await UserResetPasswordTokenModel.query(on: req.db)
                    .filter(\.$token == token)
                    .first()
                
                isUnique = existingToken == nil
            } catch {
                print(error)
            }
            
        } while !isUnique
        
        let tokenModel = UserResetPasswordTokenModel(userId: userId, token: token)
        try await tokenModel.create(on: req.db)
        
        return .init(id: try tokenModel.requireID(), token: tokenModel.token, isUsed: tokenModel.isUsed, createdAt: tokenModel.createdAt)
    }
}
