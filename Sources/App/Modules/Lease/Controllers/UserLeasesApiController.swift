//
//  UserLeasesApiController.swift
//
//
//  Created by Mico Miloloza on 02.05.2024..
//

import Vapor
import Fluent


extension Armory.Lease.Create: Content {}
extension Armory.Lease.Detail: Content {}
extension Armory.Lease.List: Content {}


struct UserLeasesApiController: ListController {
    
    typealias ApiModel = Armory.Lease
    typealias DatabaseModel = LeaseModel
    typealias CreateObject = Armory.Lease.Create
    typealias UpdateObject = Armory.Lease.Update
    typealias DetailObject = Armory.Lease.Detail
    typealias PatchObject = Armory.Lease.Patch
    typealias ListObject = Armory.Lease.List
    
    var parameterId: String = "leaseId"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        baseRoutes.on(.GET, "user-leases", use: getUserLeases)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.PUT, use: updateApi)
//        existingModelRoutes.on(.PATCH, use: patchApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
}


extension UserLeasesApiController {
    func createApi(_ req: Request) async throws -> DetailObject {
        let input = try req.content.decode(CreateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let userId = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        // Create the lease model
        let leaseModel = try LeaseModel(userId: userId)
        try await leaseModel.save(on: req.db)
        
        // Process lease items
        let leaseItems = try input.items.map { item in
            LeaseItemModel(leaseId: try leaseModel.requireID(), armoryItemId: item.armoryItemId, quantity: item.quantity)
        }
        
        // Verify and update inStock in a single transaction
        try await req.db.transaction { db in
            for leaseItem in leaseItems {
                guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                
                if armoryItem.inStock < leaseItem.quantity {
                    throw ArmoryErrors.insufficientArmoryItemStock(itemName: armoryItem.name, requested: leaseItem.quantity, available: armoryItem.inStock)
                }
                
                // Update inStock
                armoryItem.inStock -= leaseItem.quantity
                
                try await armoryItem.save(on: db)
            }
            
            // Save lease items
            try await leaseItems.create(on: db)
        }
        
        // Fetch the updated lease model with related data
        guard let createdLeaseModel = try await LeaseModel.query(on: req.db)
            .filter(\.$id == leaseModel.requireID())
            .with(\.$user)
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
        let createdLeaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == createdLeaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var armoryItems: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
        
        for leaseItem in createdLeaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            try await armoryItem.$category.load(on: req.db)
            
            armoryItems.append((armoryItem, leaseItem.quantity))
        }
        
        
        let detailOutput = DetailObject(
            id: try createdLeaseModel.requireID(),
            user: .init(
                id: try createdLeaseModel.user.requireID(),
                firstName: createdLeaseModel.user.firstName,
                lastName: createdLeaseModel.user.lastName,
                email: createdLeaseModel.user.email,
                isAdmin: createdLeaseModel.user.isAdmin,
                imageKey: createdLeaseModel.user.imageKey),
            armoryItems: try armoryItems.map { (armoryItem, quantity) in
                .init(
                    armoryItem: .init(
                        id: try armoryItem.requireID(),
                        name: armoryItem.name,
                        imageKey: armoryItem.imageKey,
                        aboutInfo: armoryItem.aboutInfo,
                        inStock: armoryItem.inStock,
                        category: .init(id: try armoryItem.category.requireID(),
                                        name: armoryItem.category.name,
                                        imageKey: armoryItem.category.imageKey),
                        categoryId: try armoryItem.category.requireID()),
                    quantity: quantity)
            },
            createdAt: createdLeaseModel.createdAt,
            updatedAt: createdLeaseModel.updatedAt,
            deletedAt: createdLeaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseCreated, detailOutput)
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .dashboardUpdate, detailOutput)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let leaseModel = try await findBy(identifier(req), on: req.db)
        
        // Fetch all lease items associated with this lease
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        let leaseModelId = try leaseModel.requireID()
        
        // Start a transaction to ensure atomic updates
        try await req.db.transaction { db in
            // Restore stock for each armory item based on the quantity in the lease
            for leaseItem in leaseItems {
                guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                
                // Restore the stock count
                armoryItem.inStock += leaseItem.quantity
                
                // Save the updated armory item
                try await armoryItem.save(on: db)
            }
            
            // Delete the lease items
            try await leaseItems.delete(on: db)
            
            // Delete the lease itself
            try await leaseModel.delete(on: db)
        }
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseDeleted, leaseModelId)
        
        return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        
        guard let leaseModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var armoryItemsWithCategories: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
        
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            try await armoryItem.$category.load(on: req.db)
            
            armoryItemsWithCategories.append((armoryItem, leaseItem.quantity))
        }
        
        
        return .init(id: try leaseModel.requireID(),
                     user: .init(id: try leaseModel.user.requireID(),
                                 firstName: leaseModel.user.firstName,
                                 lastName: leaseModel.user.lastName,
                                 email: leaseModel.user.email,
                                 isAdmin: leaseModel.user.isAdmin,
                                 imageKey: leaseModel.user.imageKey),
                     armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name,
                                                        imageKey: armoryItem.category.imageKey),
                                        categoryId: try armoryItem.category.requireID()),
                      quantity: quantity) },
                     createdAt: leaseModel.createdAt,
                     updatedAt: leaseModel.updatedAt,
                     deletedAt: leaseModel.deletedAt
        )
    }
    
    func updateApi(_ req: Request) async throws -> DetailObject {
        let updateObject = try req.content.decode(UpdateObject.self)
        
        // Fetch the existing lease, including user and items
        guard let leaseModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.leaseNotFound
        }
        
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
                
                throw Abort(.badRequest, reason: "Invalid quantity for armory item \(armoryItemModel.name).")
            }
            
            // Check if there is enough stock to lease
            if armoryItemModel.inStock < armoryItem.quantity {
                throw Abort(.badRequest, reason: "Not enough stock for item \(armoryItemModel.name). Only \(armoryItemModel.inStock) left.")
            }
            
            // Deduct the stock
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
//            let ddd = try leaseItem.joined(ArmoryItemModel.self)
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
                                 email: leaseModel.user.email,
                                 isAdmin: leaseModel.user.isAdmin,
                                 imageKey: leaseModel.user.imageKey),
                     armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name,
                                                        imageKey: armoryItem.category.name),
                                        categoryId: try armoryItem.category.requireID()),
                      quantity: quantity) },
                     createdAt: leaseModel.createdAt,
                     updatedAt: leaseModel.updatedAt,
                     deletedAt: leaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseUpdated, updatedLeaseItem)
        
        return updatedLeaseItem
    }
    
    func listApi(_ req: Request) async throws -> ListObject {
        let models = try await paginatedList(req,
                                    queryBuilders: { $0.with(\.$user) }
        )
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let leaseItems = try await LeaseItemModel.query(on: req.db)
                .filter(\.$leaseId == leaseModel.requireID())
                .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
                .all()
            
            var armoryItems: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
            
            for leaseItem in leaseItems {
                let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
                try await armoryItem.$category.load(on: req.db)
                
                armoryItems.append((armoryItem, leaseItem.quantity))
            }
            
            leases.append(.init(id: try leaseModel.requireID(),
                                user: .init(id: try leaseModel.user.requireID(),
                                            firstName: leaseModel.user.firstName,
                                            lastName: leaseModel.user.lastName,
                                            email: leaseModel.user.email,
                                            isAdmin: leaseModel.user.isAdmin,
                                            imageKey: leaseModel.user.imageKey),
                                armoryItems: try armoryItems.map { armoryItem, quantity in
                    .init(armoryItem: .init(id: try armoryItem.requireID(),
                                            name: armoryItem.name,
                                            imageKey: armoryItem.imageKey,
                                            aboutInfo: armoryItem.aboutInfo,
                                            inStock: armoryItem.inStock,
                                            category: .init(id: armoryItem.category.id!,
                                                            name: armoryItem.category.name,
                                                            imageKey: armoryItem.category.name),
                                            categoryId: try armoryItem.category.requireID()),
                          quantity: quantity)},
                                createdAt: leaseModel.createdAt,
                                updatedAt: leaseModel.updatedAt,
                                deletedAt: leaseModel.deletedAt
                               )
            )
        }
        
        
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
    
    func getUserLeases(_ req: Request) async throws -> ListObject {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        let userId = try user.requireID()
        
        let models = try await paginatedList(req,
                                    queryBuilders: { $0.with(\.$user) },
                                    { $0.filter(\.$user.$id == userId) }
        )
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let leaseItems = try await LeaseItemModel.query(on: req.db)
                .filter(\.$leaseId == leaseModel.requireID())
                .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
                .all()
            
            var armoryItems: [(armoryItem: ArmoryItemModel, quantity: Int)] = []
            
            for leaseItem in leaseItems {
                let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
                try await armoryItem.$category.load(on: req.db)
                
                armoryItems.append((armoryItem, leaseItem.quantity))
            }
            
            leases.append(.init(id: try leaseModel.requireID(),
                                user: .init(id: try leaseModel.user.requireID(),
                                            firstName: leaseModel.user.firstName,
                                            lastName: leaseModel.user.lastName,
                                            email: leaseModel.user.email,
                                            isAdmin: leaseModel.user.isAdmin,
                                            imageKey: leaseModel.user.imageKey),
                                armoryItems: try armoryItems.map { armoryItem, quantity in
                    .init(armoryItem: .init(id: try armoryItem.requireID(),
                                            name: armoryItem.name,
                                            imageKey: armoryItem.imageKey,
                                            aboutInfo: armoryItem.aboutInfo,
                                            inStock: armoryItem.inStock,
                                            category: .init(id: armoryItem.category.id!,
                                                            name: armoryItem.category.name,
                                                            imageKey: armoryItem.category.imageKey),
                                            categoryId: try armoryItem.category.requireID()
                                           ),
                          quantity: quantity)},
                                createdAt: leaseModel.createdAt,
                                updatedAt: leaseModel.updatedAt,
                                deletedAt: leaseModel.deletedAt
                               )
            )
        }
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
}
