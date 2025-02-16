//
//  LeaseStateChange.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.02.2025..
//

import Vapor
import Fluent


extension UserLeasesApiController {
    func updateLease(_ req: Request, leaseModel: DatabaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        // If lease is closed you cannot update it
        if leaseModel.returned { throw ArmoryErrors.leaseAlreadyClosed }
        
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var armoryItems: [ArmoryItemModel] = []
        
        // Revert stock for previous lease items
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            armoryItem.inStock += leaseItem.quantity
            try await armoryItem.update(on: req.db)
            
            try await armoryItem.$category.load(on: req.db)
            
            armoryItems.append(armoryItem)
        }
        
        // Delete existing lease items
        try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .delete()
        
        var newLeaseItems: [LeaseItemModel] = []
        
        // Prepare new lease items and update stock
        for armoryItem in updateObject.items {
            guard let armoryItemModel = try await ArmoryItemModel.find(armoryItem.armoryItemId, on: req.db) else {
                throw ArmoryErrors.armoryItemNotFound
            }
            guard armoryItem.quantity > 0 else {
                throw ArmoryErrors.armoryItemQuantityNotSufficient
            }
            
            // Check if there is enough stock to lease
            if armoryItemModel.inStock < armoryItem.quantity {
                throw ArmoryErrors.insufficientArmoryItemStock(itemName: armoryItemModel.name, requested: armoryItem.quantity, available: armoryItemModel.inStock)
            }
            
            // Deduct the stockarmoryItemQuantityNotSufficient
            armoryItemModel.inStock -= armoryItem.quantity
            try await armoryItemModel.update(on: req.db)
            
            // Create new lease item
            let newLeaseItem = LeaseItemModel(
                leaseId: try leaseModel.requireID(),
                armoryItemId: armoryItem.armoryItemId,
                quantity: armoryItem.quantity
            )
            
            try await newLeaseItem.create(on: req.db)
            
            newLeaseItems.append(newLeaseItem)
        }
        
        // Update the lease record if necessary
        try await leaseModel.update(on: req.db)
        
        var armoryItemsWithCategories: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
        
        for leaseItem in newLeaseItems {
            guard let armoryItemModel = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: req.db) else {
                throw Abort(.badRequest, reason: "Armory item couldn't be found")
            }
            try await armoryItemModel.$category.load(on: req.db)
            
            armoryItemsWithCategories.append((armoryItemModel, leaseItem.quantity))
        }
        
        
        let updatedLeaseItem = Armory.Lease.Detail(id: try leaseModel.requireID(),
                                                   user: .init(id: try leaseModel.user.requireID(),
                                                               firstName: leaseModel.user.firstName,
                                                               lastName: leaseModel.user.lastName,
                                                               imageKey: leaseModel.user.imageKey,
                                                               email: leaseModel.user.email,
                                                               isAdmin: leaseModel.user.isAdmin),
                                                   returned: leaseModel.returned,
                                                   armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name),
                                        categoryId: try armoryItem.category.requireID(),
                                        createdAt: armoryItem.createdAt,
                                        updatedAt: armoryItem.updatedAt,
                                        deletedAt: armoryItem.deletedAt),
                      quantity: quantity) },
                                                   createdAt: leaseModel.createdAt,
                                                   updatedAt: leaseModel.updatedAt,
                                                   deletedAt: leaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, updatedLeaseItem)
        
        return updatedLeaseItem
    }
    
    func closeLease(_ req: Request, leaseModel: DatabaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var armoryItems: [ArmoryItemModel] = []
        
        // Revert stock for previous lease items
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            
            armoryItem.inStock += leaseItem.quantity
            try await armoryItem.update(on: req.db)
            
            try await armoryItem.$category.load(on: req.db)
            
            armoryItems.append(armoryItem)
        }
        
        leaseModel.returned = updateObject.returned
        // Update the lease record if necessary
        try await leaseModel.update(on: req.db)
        
        var armoryItemsWithCategories: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
        
        for leaseItem in leaseItems {
            guard let armoryItemModel = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: req.db) else {
                continue//throw Abort(.badRequest, reason: "Armory item couldn't be found")
            }
            try await armoryItemModel.$category.load(on: req.db)
            
            armoryItemsWithCategories.append((armoryItemModel, leaseItem.quantity))
        }
        
        
        let closedLease = Armory.Lease.Detail(id: try leaseModel.requireID(),
                                                   user: .init(id: try leaseModel.user.requireID(),
                                                               firstName: leaseModel.user.firstName,
                                                               lastName: leaseModel.user.lastName,
                                                               imageKey: leaseModel.user.imageKey,
                                                               email: leaseModel.user.email,
                                                               isAdmin: leaseModel.user.isAdmin),
                                                   returned: leaseModel.returned,
                                                   armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name),
                                        categoryId: try armoryItem.category.requireID(),
                                        createdAt: armoryItem.createdAt,
                                        updatedAt: armoryItem.updatedAt,
                                        deletedAt: armoryItem.deletedAt),
                      quantity: quantity) },
                                                   createdAt: leaseModel.createdAt,
                                                   updatedAt: leaseModel.updatedAt,
                                                   deletedAt: leaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, closedLease)
        
        return closedLease
    }
    
    func openLease(_ req: Request, leaseModel: DatabaseModel, updateObject: UpdateObject) async throws -> DetailObject {
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var armoryItems: [ArmoryItemModel] = []
        
        // Revert stock for previous lease items
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            
            armoryItem.inStock -= leaseItem.quantity
            try await armoryItem.update(on: req.db)
            
            try await armoryItem.$category.load(on: req.db)
            
            armoryItems.append(armoryItem)
        }
        
        leaseModel.returned = updateObject.returned
        // Update the lease record if necessary
        try await leaseModel.update(on: req.db)
        
        var armoryItemsWithCategories: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
        
        for leaseItem in leaseItems {
            guard let armoryItemModel = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: req.db) else {
                continue//throw Abort(.badRequest, reason: "Armory item couldn't be found")
            }
            try await armoryItemModel.$category.load(on: req.db)
            
            armoryItemsWithCategories.append((armoryItemModel, leaseItem.quantity))
        }
        
        
        let openedLease = Armory.Lease.Detail(id: try leaseModel.requireID(),
                                                   user: .init(id: try leaseModel.user.requireID(),
                                                               firstName: leaseModel.user.firstName,
                                                               lastName: leaseModel.user.lastName,
                                                               imageKey: leaseModel.user.imageKey,
                                                               email: leaseModel.user.email,
                                                               isAdmin: leaseModel.user.isAdmin),
                                                   returned: leaseModel.returned,
                                                   armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name),
                                        categoryId: try armoryItem.category.requireID(),
                                        createdAt: armoryItem.createdAt,
                                        updatedAt: armoryItem.updatedAt,
                                        deletedAt: armoryItem.deletedAt),
                      quantity: quantity) },
                                                   createdAt: leaseModel.createdAt,
                                                   updatedAt: leaseModel.updatedAt,
                                                   deletedAt: leaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, openedLease)
        
        return openedLease
    }
    
}
