//
//  RegistrationCodeModel.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 11.03.2025..
//

import Vapor
import Fluent

final class RegistrationTokenModel: DatabaseModelInterface, Codable {
    typealias Module = UserModule
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.v1.token)
    var code: String
    
    @Field(key: FieldKeys.v1.isUsed)
    var isUsed: Bool
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(code: String) {
        self.code = code
        self.isUsed = false
    }
}

extension RegistrationTokenModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var token: FieldKey { "token" }
            static var isUsed: FieldKey { "is_used" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
}
