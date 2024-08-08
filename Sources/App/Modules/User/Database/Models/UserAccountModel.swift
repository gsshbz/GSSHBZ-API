//
//  UserAccountModel.swift
//  
//
//  Created by Mico Miloloza on 28.06.2023..
//

import Vapor
import Fluent


final class UserAccountModel: DatabaseModelInterface {
    typealias Module = UserModule
    
    @ID()
    var id: UUID?
    
    @Field(key: FieldKeys.v1.firstName)
    var firstName: String
    
    @Field(key: FieldKeys.v1.lastName)
    var lastName: String
    
    @Field(key: FieldKeys.v1.username)
    var username: String
    
    @Field(key: FieldKeys.v1.email)
    var email: String
    
    @Field(key: FieldKeys.v1.password)
    var password: String
    
    @OptionalField(key: FieldKeys.v1.phoneNumber)
    var phoneNumber: String?
    
    @OptionalField(key: FieldKeys.v1.address)
    var address: String?
    
    @OptionalField(key: FieldKeys.v1.profileImageUrlString)
    var profileImageUrlString: String?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    @Children(for: \.$user)
    var leases: [LeaseModel]
    
    init() { }
    
    init(id: UUID? = nil, firstName: String, lastName: String, username: String, email: String, password: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.password = password
    }
    
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var firstName: FieldKey { "first_name" }
            static var lastName: FieldKey { "last_name" }
            static var username: FieldKey { "username" }
            static var email: FieldKey { "email" }
            static var password: FieldKey { "password" }
            static var phoneNumber: FieldKey { "phone_number" }
            static var address: FieldKey { "address" }
            static var profileImageUrlString: FieldKey { "profile_image_url_string"}
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}


extension UserAccountModel: ModelAuthenticatable {
    static let usernameKey = \UserAccountModel.$username
    static let passwordHashKey = \UserAccountModel.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension UserAccountModel {
    func createRefreshToken(source: SessionSource) throws -> OAuthToken {
        return try OAuthToken.generate(for: self, source: source)
    }
    
    static func create(from registerData: User.Account.Create, hash: String, registrationType: RegistrationType) -> UserAccountModel {
        return UserAccountModel(firstName: registerData.firstName,
                                lastName: registerData.lastName,
                                username: registerData.username,
                                email: registerData.email,
                                password: hash)
    }
}
