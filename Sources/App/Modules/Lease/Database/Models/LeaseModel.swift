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
    
    @Siblings(through: LeaseItemModel.self, from: \.$lease, to: \.$armoryItem)
    var armoryItems: [ArmoryItemModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
//    @Field(key: "leased_at")
//    var leasedAt: Date
//    
//    @Field(key: "returned_at")
//    var returnedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, userId: UUID) throws {
        self.id = id
        self.$user.id = userId
    }
}


extension LeaseModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var userId: FieldKey { "user_id" }
            static var leaseId: FieldKey { "lease_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}

