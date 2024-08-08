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

    @Parent(key: FieldKeys.v1.leaseId)
    var lease: LeaseModel

    @Parent(key: FieldKeys.v1.armoryItemId)
    var armoryItem: ArmoryItemModel

    init() {}

    init(id: UUID? = nil, leaseId: UUID, armoryItemId: UUID) {
        self.id = id
        self.$lease.id = leaseId
        self.$armoryItem.id = armoryItemId
    }
}

extension LeaseItemModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var leaseId: FieldKey { "lease_id" }
            static var armoryItemId: FieldKey { "armory_item_id" }
        }
    }
}

