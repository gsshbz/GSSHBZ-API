//
//  UserResetPasswordTokenModel.swift
//
//
//  Created by Mico Miloloza on 04.09.2024..
//

import Fluent
import Vapor


final class UserResetPasswordTokenModel: DatabaseModelInterface, Content {
    typealias Module = UserModule
    
    @ID
    var id: UUID?
    
    @OptionalParent(key: FieldKeys.v2.userId)
    var user: UserAccountModel?
    
    @Field(key: FieldKeys.v1.token)
    var token: String
    
    @Field(key: FieldKeys.v1.isUsed)
    var isUsed: Bool
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Field(key: FieldKeys.v1.expiresAt)
    var expiresAt: Date
    
    init() {}
    
    init(id: UUID? = nil, userId: UUID? = nil, token: String, expiresAt: Date = Date().addingTimeInterval(Constants.RESET_PASSWORD_TOKEN_LIFETIME)) {
        self.id = id
        if let userId = userId {
            self.$user.id = userId
        }
        self.token = token
        self.isUsed = false
        self.expiresAt = expiresAt
    }
}

extension UserResetPasswordTokenModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var token: FieldKey { "token" }
            static var isUsed: FieldKey {"is_used" }
            static var createdAt: FieldKey { "created_at" }
            static var expiresAt: FieldKey { "expires_at" }
        }
        
        struct v2 {
            static var userId: FieldKey { "user_id" }
        }
    }
}
