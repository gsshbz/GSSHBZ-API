//
//  EmailTokenModel.swift
//
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor
import Fluent


final class EmailTokenModel: DatabaseModelInterface {
    typealias Module = UserModule
    
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: FieldKeys.v1.userId)
    var user: UserAccountModel
    
    @Field(key: FieldKeys.v1.token)
    var token: String
    
    @Field(key: FieldKeys.v1.expiresAt)
    var expiresAt: Date
    
    init() {}
    
    init(
        id: UUID? = nil,
        userId: UUID,
        token: String,
        expiresAt: Date = Date().addingTimeInterval(Constants.EMAIL_TOKEN_LIFETIME)
    ) {
        self.id = id
        self.$user.id = userId
        self.token = token
        self.expiresAt = expiresAt
    }
}


extension EmailTokenModel {
    struct FieldKeys {
        struct v1 {
            static var schema: FieldKey { "user_email_tokens" }
            static var id: FieldKey { "id" }
            static var userId: FieldKey { "user_id" }
            static var token: FieldKey { "token" }
            static var expiresAt: FieldKey {"expires_at" }
        }
    }
}
