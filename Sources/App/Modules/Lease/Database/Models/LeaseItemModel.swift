//
//  LeaseItemModel.swift
//
//
//  Created by Mico Miloloza on 06.08.2024..
//

import Vapor
import Fluent


final class LeaseItemModel: DatabaseModelInterface {
    typealias Module = LeaseModule

    @ID()
    var id: UUID?

    @Field(key: FieldKeys.v1.leaseId)
    var leaseId: UUID

    @Field(key: FieldKeys.v1.armoryItemId)
    var armoryItemId: UUID
    
    @Field(key: FieldKeys.v1.quantity)
    var quantity: Int

    init() {}

    init(id: UUID? = nil, leaseId: UUID, armoryItemId: UUID, quantity: Int) {
        self.id = id
        self.leaseId = leaseId
        self.armoryItemId = armoryItemId
        self.quantity = quantity
    }
}

extension LeaseItemModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var leaseId: FieldKey { "lease_id" }
            static var armoryItemId: FieldKey { "armory_item_id" }
            static var quantity: FieldKey { "quantity" }
        }
    }
}

