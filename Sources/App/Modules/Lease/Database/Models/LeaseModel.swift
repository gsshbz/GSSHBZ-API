//
//  LeaseModel.swift
//
//
//  Created by Mico Miloloza on 04.04.2024..
//

import Vapor
import Fluent


final class LeaseModel: DatabaseModelInterface {
    typealias Module = LeaseModule
    
    @ID
    var id: UUID?
    
    @Parent(key: FieldKeys.v1.userId)
    var user: UserAccountModel
    
    @Field(key: FieldKeys.v1.returned)
    var returned: Bool
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, userId: UUID, returned: Bool = false) throws {
        self.id = id
        self.$user.id = userId
        self.returned = returned
    }
}


extension LeaseModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var userId: FieldKey { "user_id" }
            static var returned: FieldKey { "returned" }
            static var leaseId: FieldKey { "lease_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}

