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
    
//    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [Armory.Lease.List] {
//        try models.map { model in
//                .init(id: model.id!,
//                      user: .init(id: try model.user.requireID(), firstName: model.user.firstName, lastName: model.user.lastName, email: model.user.email),
//                      armoryItems: model.armoryItems.map { .init(id: $0.id!,
//                                                                 name: $0.name,
//                                                                 imageKey: $0.imageKey,
//                                                                 aboutInfo: $0.aboutInfo,
//                                                                 inStock: $0.inStock,
//                                                                 category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) }, 
//                      metadata: nil
//                )
//        }
//    }
    
//    func paginatedListOutput(_ req: Request, _ paginatedModel: Page<DatabaseModel>) async throws -> [Armory.Lease.List] {
//        try paginatedModel.items.map { model in
//                .init(id: model.id!,
//                      user: .init(id: try model.user.requireID(), firstName: model.user.firstName, lastName: model.user.lastName, email: model.user.email),
//                      armoryItems: model.armoryItems.map { .init(id: $0.id!,
//                                                                 name: $0.name,
//                                                                 imageKey: $0.imageKey,
//                                                                 aboutInfo: $0.aboutInfo,
//                                                                 inStock: $0.inStock,
//                                                                 category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) }, 
//                      metadata: .init(page: paginatedModel.metadata.page, per: paginatedModel.metadata.per, total: paginatedModel.metadata.total)
//                )
//        }
//    }
    
//    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> Armory.Lease.Detail {
//        return .init(id: model.id!, user: .init(id: try model.user.requireID(), firstName: model.user.firstName, lastName: model.user.lastName, email: model.user.email),
//                         armoryItems: model.armoryItems.map { .init(id: $0.id!,
//                                                                    name: $0.name,
//                                                                    imageKey: $0.imageKey,
//                                                                    aboutInfo: $0.aboutInfo,
//                                                                    inStock: $0.inStock,
//                                                                    category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) })
//    }
    
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Lease.Create) async throws {
    }
    
    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Lease.Update) async throws {
    }
    
    func patchInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Lease.Patch) async throws {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        model.user = user
    }
    
    
    func createResponse(_ req: Vapor.Request, _ model: LeaseModel) async throws -> Response {
        return Response(status: .ok)
    }
    
    func updateResponse(_ req: Vapor.Request, _ model: LeaseModel) async throws -> Response {
        return Response(status: .ok)
    }
    
    func patchResponse(_ req: Vapor.Request, _ model: LeaseModel) async throws -> Response {
        return Response(status: .ok)
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
        
        let armoryItems = try createdLeaseItems.map { try $0.joined(ArmoryItemModel.self) }
        
        let detailOutput = DetailObject(id: try createdLeaseModel.requireID(), user: .init(id: try createdLeaseModel.user.requireID(), firstName: createdLeaseModel.user.firstName, lastName: createdLeaseModel.user.lastName, email: createdLeaseModel.user.email), armoryItems: try armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: $0.category != nil ? .init(id: try $0.category!.requireID(), name: $0.category!.name) : nil) })
        
        try await ArmoryWebSocketSystem.shared.broadcastNewLeaseCreated(detailOutput)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        try await model.delete(on: req.db)
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
        
        var armoryItemsWithCategories: [ArmoryItemModel] = []
        
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            let category = try await armoryItem.$category.get(on: req.db)
            
            if let category = category {
                print("Category: \(category.name)")
            } else {
                print("No category for this item")
            }
            
            armoryItemsWithCategories.append(armoryItem)
        }
        
        
        return .init(id: try leaseModel.requireID(), user: .init(id: try leaseModel.user.requireID(), firstName: leaseModel.user.firstName, lastName: leaseModel.user.lastName, email: leaseModel.user.email),
                     armoryItems: armoryItemsWithCategories.map { .init(id: $0.id!,
                                                                name: $0.name,
                                                                imageKey: $0.imageKey,
                                                                aboutInfo: $0.aboutInfo,
                                                                inStock: $0.inStock,
                                                                category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) })
//        return try await detailOutput(req, leaseModel)
    }
    
//    func patchApi(_ req: Request) async throws -> Response {
//        let jwtUser = try req.auth.require(JWTUser.self)
//        
//        guard let leaseModel = try await DatabaseModel.query(on: req.db)
//            .with(\.$user)
//            .with(\.$armoryItems)
//            .filter(\.$id == identifier(req))
//            .first() else {
//            throw Abort(.notFound)
//        }
//        
//        let patchObject = try req.content.decode(PatchObject.self)
//        
//
//
//        try await model.update(on: req.db)
//        return try await patchResponse(req, model)
//    }
    
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
        return try await updateResponse(req, leaseModel)
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
            
            var armoryItems: [ArmoryItemModel] = []
            
            for leaseItem in leaseItems {
                let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
                let category = try await armoryItem.$category.query(on: req.db).first()
                
                if let category = category {
                    print("Category: \(category.name)")
                } else {
                    print("No category for this item")
                }
                
                armoryItems.append(armoryItem)
            }
            
            leases.append(.init(id: try leaseModel.requireID(), user: .init(id: try leaseModel.user.requireID(), firstName: leaseModel.user.firstName, lastName: leaseModel.user.lastName, email: leaseModel.user.email), armoryItems: try armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) }))
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
            
            var armoryItems: [ArmoryItemModel] = []
            
            for leaseItem in leaseItems {
                let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
                let category = try await armoryItem.$category.query(on: req.db).first()
                
                if let category = category {
                    print("Category: \(category.name)")
                } else {
                    print("No category for this item")
                }
                
                armoryItems.append(armoryItem)
            }
            
            leases.append(.init(id: try leaseModel.requireID(), user: .init(id: try leaseModel.user.requireID(), firstName: leaseModel.user.firstName, lastName: leaseModel.user.lastName, email: leaseModel.user.email), armoryItems: try armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) }))
            
        }
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
}


struct LeaseMapper {
//    static func mapToList(_ models: [LeaseModel], leaseItems: [LeaseItemModel]) throws -> [Armory.Lease.List] {
//        try models.map { model in
////            let items = try leaseItemsForModel(model, in: leaseItems)
//            return Armory.Lease.List(
//                id: try model.requireID(),
//                user: .init(id: try model.user.requireID(), firstName: model.user.firstName, lastName: model.user.lastName, email: model.user.email),
//                armoryItems: try model.armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: $0.category != nil ? .init(id: try $0.category!.requireID(), name: $0.category!.name) : nil) },
//                metadata: nil
//            )
//        }
//    }
//    
//    static func mapToDetail(_ model: LeaseModel, leaseItems: [LeaseItemModel]) throws -> Armory.Lease.Detail {
////        let items = try leaseItemsForModel(model, in: leaseItems)
//        return Armory.Lease.Detail(
//            id: try model.requireID(),
//            user: .init(id: try model.user.requireID(), firstName: model.user.firstName, lastName: model.user.lastName, email: model.user.email),
//            armoryItems: try model.armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: $0.category != nil ? .init(id: try $0.category!.requireID(), name: $0.category!.name) : nil) }
//        )
//    }
    
//    private static func leaseItemsForModel(_ model: LeaseModel, in leaseItems: [LeaseItemModel]) throws -> [Armory.Lease.List] {
//        try leaseItems.filter { $0.lease.id == model.id }.map { leaseItem in
//            Armory.Lease.List(
//                armoryItem: .init(
//                    id: try leaseItem.armoryItem.requireID(),
//                    name: leaseItem.armoryItem.name,
//                    imageKey: leaseItem.armoryItem.imageKey,
//                    aboutInfo: leaseItem.armoryItem.aboutInfo,
//                    inStock: leaseItem.armoryItem.inStock,
//                    category: leaseItem.armoryItem.category != nil ? .init(id: leaseItem.armoryItem.category!.id!, name: leaseItem.armoryItem.category!.name) : nil
//                ),
//                quantity: leaseItem.quantity
//            )
//        }
//    }
}
