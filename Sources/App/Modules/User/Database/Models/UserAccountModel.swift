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
    
    @Field(key: FieldKeys.v1.email)
    var email: String
    
    @Field(key: FieldKeys.v1.password)
    var password: String
    
    @Field(key: FieldKeys.v1.isAdmin)
    var isAdmin: Bool
    
    @OptionalField(key: FieldKeys.v1.phoneNumber)
    var phoneNumber: String?
    
    @OptionalField(key: FieldKeys.v1.address)
    var address: String?
    
    @OptionalField(key: FieldKeys.v1.imageKey)
    var imageKey: String?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    @Children(for: \.$user)
    var leases: [LeaseModel]
    
    init() { }
    
    init(id: UUID? = nil, firstName: String, lastName: String, email: String, password: String, phoneNumber: String?, address: String?, imageKey: String?, isAdmin: Bool = false) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.phoneNumber = phoneNumber
        self.address = address
        self.imageKey = imageKey
        self.isAdmin = isAdmin
    }
    
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var firstName: FieldKey { "first_name" }
            static var lastName: FieldKey { "last_name" }
            static var email: FieldKey { "email" }
            static var password: FieldKey { "password" }
            static var phoneNumber: FieldKey { "phone_number" }
            static var address: FieldKey { "address" }
            static var isAdmin: FieldKey { "is_admin" }
            static var imageKey: FieldKey { "image_key" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}


extension UserAccountModel: ModelAuthenticatable {
    static let usernameKey = \UserAccountModel.$email
    static let passwordHashKey = \UserAccountModel.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension UserAccountModel {
    func createRefreshToken(source: SessionSource) throws -> OAuthToken {
        return try OAuthToken.generate(for: self, source: source)
    }
    
    static func create(from registerData: User.Account.Create, req: Request, hash: String, registrationType: RegistrationType) async throws -> UserAccountModel {
//        var publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/default-avatar.jpg"
        
//        if let image = registerData.image {
//            // Validate MIME type
//            guard ["image/jpeg", "image/png"].contains(image.contentType?.description) else {
//                throw Abort(.unsupportedMediaType, reason: "Only JPEG and PNG images are allowed.")
//            }
//            
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
//            publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/\(uniqueFileName)"
//        }
        
        return UserAccountModel(firstName: registerData.firstName,
                                lastName: registerData.lastName,
                                email: registerData.email,
                                password: hash,
                                phoneNumber: registerData.phoneNumber,
                                address: registerData.address,
                                imageKey: registerData.imageKey ?? "0")
    }
}
