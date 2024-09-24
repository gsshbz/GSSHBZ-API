//
//  ResetPasswordTokenModel.swift
//
//
//  Created by Mico Miloloza on 04.09.2024..
//

import Fluent
import Vapor


final class ResetPasswordTokenModel: DatabaseModelInterface, Content {
    typealias Module = UserModule
    
    @ID
    var id: UUID?
    
    @Field(key: FieldKeys.v1.token)
    var token: String
    
    @Parent(key: FieldKeys.v1.userId)
    var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Field(key: FieldKeys.v1.expiresAt)
    var expiresAt: Date
    
    init() {}
    
    init(id: UUID? = nil, token: String, userId: UserAccountModel.IDValue) {
        self.id = id
        self.token = token
        self.$user.id = userId
    }
}

extension ResetPasswordTokenModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var token: FieldKey { "token" }
            static var userId: FieldKey { "user_id" }
            static var expiresAt: FieldKey { "expires_at" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
}
