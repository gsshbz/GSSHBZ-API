//
//  LeaseStateChange.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.02.2025..
//

import Vapor
import Fluent


extension UserLeasesApiController {
    func updateLease(_ req: Request, leaseModel: LeaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        
        // Fetch existing lease items
        let existingLeaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        // Build lookup maps
        let existingByItemId = Dictionary(uniqueKeysWithValues: existingLeaseItems.map { ($0.armoryItemId, $0) })
        let newByItemId = Dictionary(uniqueKeysWithValues: updateObject.items.map { ($0.armoryItemId, $0) })
        
        let removedItems = existingLeaseItems.filter { newByItemId[$0.armoryItemId] == nil }
        let addedItems   = updateObject.items.filter { existingByItemId[$0.armoryItemId] == nil }
        let changedItems = updateObject.items.filter {
            guard let existing = existingByItemId[$0.armoryItemId] else { return false }
            return existing.quantity != $0.quantity
        }
        
        try await req.db.transaction { db in
            
            // 1. Removed items — restore their stock fully
            for item in removedItems {
                guard let armoryItem = try await ArmoryItemModel.find(item.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                armoryItem.inStock += item.quantity
                try await armoryItem.save(on: db)
                try await item.delete(on: db)
            }
            
            // 2. Quantity changed — apply the delta (can be positive or negative)
            for newItem in changedItems {
                guard let existing = existingByItemId[newItem.armoryItemId],
                      let armoryItem = try await ArmoryItemModel.find(newItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                let delta = existing.quantity - newItem.quantity  // positive = returning some, negative = taking more
                armoryItem.inStock += delta
                guard armoryItem.inStock >= 0 else {
                    throw ArmoryErrors.insufficientArmoryItemStock(
                        itemName: armoryItem.name,
                        requested: newItem.quantity,
                        available: existing.quantity + armoryItem.inStock
                    )
                }
                try await armoryItem.save(on: db)
                existing.quantity = newItem.quantity
                try await existing.save(on: db)
            }
            
            // 3. Added items — deduct stock
            for newItem in addedItems {
                guard newItem.quantity > 0 else { throw ArmoryErrors.armoryItemQuantityNotSufficient }
                guard let armoryItem = try await ArmoryItemModel.find(newItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                guard armoryItem.inStock >= newItem.quantity else {
                    throw ArmoryErrors.insufficientArmoryItemStock(
                        itemName: armoryItem.name,
                        requested: newItem.quantity,
                        available: armoryItem.inStock
                    )
                }
                armoryItem.inStock -= newItem.quantity
                try await armoryItem.save(on: db)
                
                let leaseItem = LeaseItemModel(
                    leaseId: try leaseModel.requireID(),
                    armoryItemId: newItem.armoryItemId,
                    quantity: newItem.quantity
                )
                try await leaseItem.save(on: db)
            }
        }
        
        // Reload and broadcast
        guard let updatedLease = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == leaseModel.requireID())
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
        let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: updatedLease, req: req)
        
        // Broadcast each updated armory item
        for (armoryItem, _) in armoryItemsWithQuantities {
            let updatedDetail = Armory.Item.Detail(
                id: try armoryItem.requireID(),
                name: armoryItem.name,
                imageKey: armoryItem.imageKey,
                aboutInfo: armoryItem.aboutInfo,
                inStock: armoryItem.inStock,
                category: .init(id: try armoryItem.category.requireID(), name: armoryItem.category.name),
                categoryId: try armoryItem.category.requireID(),
                createdAt: armoryItem.createdAt,
                updatedAt: armoryItem.updatedAt,
                deletedAt: armoryItem.deletedAt
            )
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, updatedDetail)
        }
        
        return try await mapLeaseDetail(leaseModel: updatedLease, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
    }
    
    func closeLease(_ req: Request, leaseModel: DatabaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        try await req.db.transaction { db in
            for leaseItem in leaseItems {
                guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                armoryItem.inStock += leaseItem.quantity
                try await armoryItem.save(on: db)
            }
            leaseModel.returned = true
            try await leaseModel.update(on: db)
        }
        
        // Reload fresh data for response + broadcast
        guard let updatedLease = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == leaseModel.requireID())
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
        let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: updatedLease, req: req)
        
        for (armoryItem, _) in armoryItemsWithQuantities {
            try await armoryItem.$category.load(on: req.db)
            let updatedDetail = Armory.Item.Detail(
                id: try armoryItem.requireID(),
                name: armoryItem.name,
                imageKey: armoryItem.imageKey,
                aboutInfo: armoryItem.aboutInfo,
                inStock: armoryItem.inStock,
                category: .init(id: try armoryItem.category.requireID(), name: armoryItem.category.name),
                categoryId: try armoryItem.category.requireID(),
                createdAt: armoryItem.createdAt,
                updatedAt: armoryItem.updatedAt,
                deletedAt: armoryItem.deletedAt
            )
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, updatedDetail)
        }
        
        let closedLease = try await mapLeaseDetail(leaseModel: updatedLease, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, closedLease)
        return closedLease
    }
    
    func openLease(_ req: Request, leaseModel: DatabaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        try await req.db.transaction { db in
            for leaseItem in leaseItems {
                guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                // Validate before deducting — was missing before
                guard armoryItem.inStock >= leaseItem.quantity else {
                    throw ArmoryErrors.insufficientArmoryItemStock(
                        itemName: armoryItem.name,
                        requested: leaseItem.quantity,
                        available: armoryItem.inStock
                    )
                }
                armoryItem.inStock -= leaseItem.quantity
                try await armoryItem.save(on: db)
            }
            leaseModel.returned = false
            try await leaseModel.update(on: db)
        }
        
        guard let updatedLease = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == leaseModel.requireID())
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
        let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: updatedLease, req: req)
        
        for (armoryItem, _) in armoryItemsWithQuantities {
            try await armoryItem.$category.load(on: req.db)
            let updatedDetail = Armory.Item.Detail(
                id: try armoryItem.requireID(),
                name: armoryItem.name,
                imageKey: armoryItem.imageKey,
                aboutInfo: armoryItem.aboutInfo,
                inStock: armoryItem.inStock,
                category: .init(id: try armoryItem.category.requireID(), name: armoryItem.category.name),
                categoryId: try armoryItem.category.requireID(),
                createdAt: armoryItem.createdAt,
                updatedAt: armoryItem.updatedAt,
                deletedAt: armoryItem.deletedAt
            )
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, updatedDetail)
        }
        
        let openedLease = try await mapLeaseDetail(leaseModel: updatedLease, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, openedLease)
        return openedLease
    }
}
