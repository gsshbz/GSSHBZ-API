//
//  UserAccessoryLeasePivotModel.swift
//
//
//  Created by Mico Miloloza on 04.04.2024..
//

import Vapor
import Fluent


// Pivot model used to setup relationship between user leases and list of accessories
final class UserAccessoryLeasePivotModel: DatabaseModelInterface {
    typealias Module = UserModule
    
    @ID
    var id: UUID?
    
    @Parent(key: FieldKeys.v1.accessoryId)
    var accessory: ArmoryItemModel
    
    @Parent(key: FieldKeys.v1.leaseId)
    var lease: LeaseModel
    
    init() {}
    
    init(id: UUID? = nil, lease: LeaseModel, accessory: ArmoryItemModel) throws {
        self.id = id
        self.$lease.id = try lease.requireID()
        self.$accessory.id = try accessory.requireID()
    }
}


extension UserAccessoryLeasePivotModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var accessoryId: FieldKey { "accessory_id" }
            static var leaseId: FieldKey { "lease_id" }
        }
    }
}
