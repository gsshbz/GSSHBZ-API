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
                    throw Abort(.notFound, reason: "Armory item not found.")
                }
                
                if armoryItem.inStock < leaseItem.quantity {
                    throw Abort(.badRequest, reason: "Not enough stock available for item: \(armoryItem.name). Available: \(armoryItem.inStock), Requested: \(leaseItem.quantity)")
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
                throw Abort(.badRequest)
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
                isAdmin: createdLeaseModel.user.isAdmin),
            armoryItems: try armoryItems.map { (armoryItem, quantity) in
                .init(
                    armoryItem: .init(
                        id: try armoryItem.requireID(),
                        name: armoryItem.name,
                        imageKey: armoryItem.imageKey,
                        aboutInfo: armoryItem.aboutInfo,
                        inStock: armoryItem.inStock,
                        category: .init(id: try armoryItem.category.requireID(),
                                        name: armoryItem.category.name),
                        categoryId: try armoryItem.category.requireID()),
                    quantity: quantity)
            },
            createdAt: createdLeaseModel.createdAt,
            updatedAt: createdLeaseModel.updatedAt,
            deletedAt: createdLeaseModel.deletedAt
        )
        
        try await ArmoryWebSocketSystem.shared.broadcastNewLeaseCreated(detailOutput)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let leaseModel = try await findBy(identifier(req), on: req.db)
        
        // Fetch all lease items associated with this lease
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        // Start a transaction to ensure atomic updates
            try await req.db.transaction { db in
                // Restore stock for each armory item based on the quantity in the lease
                for leaseItem in leaseItems {
                    guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: db) else {
                        throw Abort(.notFound, reason: "Armory item not found.")
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
            
            return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        
        guard let leaseModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw Abort(.notFound)
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
                                 isAdmin: leaseModel.user.isAdmin),
                     armoryItems: try armoryItemsWithCategories.map { armoryItem, quantity in
                .init(armoryItem: .init(id: try armoryItem.requireID(),
                                        name: armoryItem.name,
                                        imageKey: armoryItem.imageKey,
                                        aboutInfo: armoryItem.aboutInfo,
                                        inStock: armoryItem.inStock,
                                        category: .init(id: try armoryItem.category.requireID(),
                                                        name: armoryItem.category.name),
                                        categoryId: try armoryItem.category.requireID()),
                      quantity: quantity) },
                     createdAt: leaseModel.createdAt,
                     updatedAt: leaseModel.updatedAt,
                     deletedAt: leaseModel.deletedAt
        )
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        let updateObject = try req.content.decode(UpdateObject.self)
        
        guard let leaseModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw Abort(.notFound)
        }
        
        let armoryItems = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id ~~ updateObject.items.compactMap { $0.armoryItemId }) // Use `~~` for "in" clause
            .all()
        
        try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .delete()
        
        for armoryItem in armoryItems {
            let armoryItemId = try armoryItem.requireID()
            let newLeaseItem = LeaseItemModel(
                leaseId: try leaseModel.requireID(),
                armoryItemId: try armoryItem.requireID(),
                quantity: updateObject.items.first(where: { $0.armoryItemId == armoryItemId })?.quantity ?? 1 // Set quantity from updateObject, or default to 1
            )
            try await newLeaseItem.create(on: req.db)
        }
        
        
        try await leaseModel.update(on: req.db)
        return Response(status: .ok)
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
                                            isAdmin: leaseModel.user.isAdmin),
                                armoryItems: try armoryItems.map { armoryItem, quantity in
                    .init(armoryItem: .init(id: try armoryItem.requireID(),
                                            name: armoryItem.name,
                                            imageKey: armoryItem.imageKey,
                                            aboutInfo: armoryItem.aboutInfo,
                                            inStock: armoryItem.inStock,
                                            category: .init(id: armoryItem.category.id!,
                                                            name: armoryItem.category.name),
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
                                            isAdmin: leaseModel.user.isAdmin),
                                armoryItems: try armoryItems.map { armoryItem, quantity in
                    .init(armoryItem: .init(id: try armoryItem.requireID(),
                                            name: armoryItem.name,
                                            imageKey: armoryItem.imageKey,
                                            aboutInfo: armoryItem.aboutInfo,
                                            inStock: armoryItem.inStock,
                                            category: .init(id: armoryItem.category.id!,
                                                            name: armoryItem.category.name),
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
