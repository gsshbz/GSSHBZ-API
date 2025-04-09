//
//  OAuthToken.swift
//
//
//  Created by Mico Miloloza on 13.02.2024..
//

import Vapor
import Fluent


//enum SessionSource: Int, Content {
//  case signup
//  case login
//}
//
enum RegistrationType: Int, Codable {
    case manual
    case googleOAuth
}
//
//final class OAuthToken: DatabaseModelInterface {
//    typealias Module = UserModule
//    
//    @ID()
//    var id: UUID?
//    
//    @Field(key: FieldKeys.v1.value)
//    var value: String
//    
//    @Parent(key: FieldKeys.v1.userId)
//    var user: User
//    
//    @Field(key: FieldKeys.v1.source)
//    var source: SessionSource
//    
//    @OptionalField(key: FieldKeys.v1.expiresAt)
//    var expiresAt: Date?
//    
//    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
//    var createdAt: Date?
//    
//    init() { }
//    
//    init(id: UUID? = nil, value: String, userId: User.IDValue, source: SessionSource, expiresAt: Date?) {
//        self.id = id
//        self.value = value
//        self.$user.id = userId
//        self.source = source
//        self.expiresAt = expiresAt
//    }
//    
//    struct FieldKeys {
//        struct v1 {
//            static var id: FieldKey { "id" }
//            static var value: FieldKey { "value" }
//            static var userId: FieldKey { "user_id" }
//            static var source: FieldKey { "source" }
//            static var expiresAt: FieldKey { "expires_at" }
//            static var createdAt: FieldKey { "created_at" }
//        }
//    }
//}
//
//
//// MARK: - Generating Token
//extension OAuthToken {
//    static func generate(for user: UserAccountModel, source: SessionSource) throws -> OAuthToken {
//        let random = [UInt8].random(count: 16).base64
//        let calendar = Calendar(identifier: .gregorian)
//        let expiryDate = calendar.date(byAdding: .hour, value: 1, to: Date())
//        
//        return try OAuthToken(value: random, userId: user.requireID(), source: source, expiresAt: expiryDate)
//    }
//}
//
//
//// MARK: - Using token
//extension OAuthToken: ModelTokenAuthenticatable {
//    typealias User = UserAccountModel
//    
//    static var valueKey = \OAuthToken.$value
//    static var userKey = \OAuthToken.$user
//    
//    
//    var isValid: Bool {
//        guard let expiryDate = expiresAt else {
//          return true
//        }
//        
//        return expiryDate > Date()
//    }
//}
