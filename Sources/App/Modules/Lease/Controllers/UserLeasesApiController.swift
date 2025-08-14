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
        baseRoutes.on(.GET, "user-leases", use: getCurrentUserLeases)
        baseRoutes.on(.GET, "active", use: getAllActiveLeasesApi)
        baseRoutes.on(.GET, "user-leases", ":userId", use: getUserLeases)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.POST, use: updateApi)
        existingModelRoutes.on(.PATCH, use: patchApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
}


extension UserLeasesApiController {
    // Helper method to fetch all armory items (with their category loaded) for a given lease
    private func fetchArmoryItemsForLease(leaseModel: LeaseModel, req: Request) async throws -> [(ArmoryItemModel, Int)] {
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .join(ArmoryItemModel.self, on: \LeaseItemModel.$armoryItemId == \ArmoryItemModel.$id)
            .all()
        
        var result: [(ArmoryItemModel, Int)] = []
        for leaseItem in leaseItems {
            let armoryItem = try leaseItem.joined(ArmoryItemModel.self)
            try await armoryItem.$category.load(on: req.db)
            result.append((armoryItem, leaseItem.quantity))
        }
        return result
    }
    
    // Helper method to map an ArmoryItemModel (with loaded category) and quantity to an Armory.Lease.Item
    private func mapArmoryItemDetail(armoryItem: ArmoryItemModel, quantity: Int, req: Request) async throws -> Armory.Lease.Detail.ArmoryItem {
        // Ensure the category is loaded already
        return .init(
            armoryItem: .init(
                id: try armoryItem.requireID(),
                name: armoryItem.name,
                imageKey: armoryItem.imageKey,
                aboutInfo: armoryItem.aboutInfo,
                inStock: armoryItem.inStock,
                category: .init(
                    id: try armoryItem.category.requireID(),
                    name: armoryItem.category.name
                ),
                categoryId: try armoryItem.category.requireID(),
                createdAt: armoryItem.createdAt,
                updatedAt: armoryItem.updatedAt,
                deletedAt: armoryItem.deletedAt
            ),
            quantity: quantity
        )
    }
    
    // Helper method to map a LeaseModel (with fetched armory items) to an Armory.Lease.Detail
    private func mapLeaseDetail(leaseModel: LeaseModel, armoryItemsWithQuantities: [(ArmoryItemModel, Int)], req: Request) async throws -> Armory.Lease.Detail {
        let armoryItemsDetails = try await armoryItemsWithQuantities.asyncMap { try await mapArmoryItemDetail(armoryItem: $0, quantity: $1, req: req) }
        
        return .init(
            id: try leaseModel.requireID(),
            user: .init(
                id: try leaseModel.user.requireID(),
                firstName: leaseModel.user.firstName,
                lastName: leaseModel.user.lastName,
                imageKey: leaseModel.user.imageKey,
                email: leaseModel.user.email,
                isAdmin: leaseModel.user.isAdmin
            ),
            returned: leaseModel.returned,
            armoryItems: armoryItemsDetails,
            createdAt: leaseModel.createdAt,
            updatedAt: leaseModel.updatedAt,
            deletedAt: leaseModel.deletedAt
        )
    }
    
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
            guard item.quantity > 0 else { throw ArmoryErrors.armoryItemQuantityNotSufficient }
            return LeaseItemModel(leaseId: try leaseModel.requireID(), armoryItemId: item.armoryItemId, quantity: item.quantity)
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
            
            
            let updatedArmoryItem: Armory.Item.Detail = .init(
                id: try armoryItem.requireID(),
                name: armoryItem.name,
                imageKey: armoryItem.imageKey,
                aboutInfo: armoryItem.aboutInfo,
                inStock: armoryItem.inStock,
                category: .init(id: try armoryItem.category.requireID(),
                                name: armoryItem.category.name),
                categoryId: try armoryItem.category.requireID(),
                createdAt: armoryItem.createdAt,
                updatedAt: armoryItem.updatedAt,
                deletedAt: armoryItem.deletedAt)
            
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, updatedArmoryItem)
        }
        
        
        let detailOutput = DetailObject(
            id: try createdLeaseModel.requireID(),
            user: .init(
                id: try createdLeaseModel.user.requireID(),
                firstName: createdLeaseModel.user.firstName,
                lastName: createdLeaseModel.user.lastName,
                imageKey: createdLeaseModel.user.imageKey,
                email: createdLeaseModel.user.email,
                isAdmin: createdLeaseModel.user.isAdmin),
            returned: createdLeaseModel.returned,
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
                            categoryId: try armoryItem.category.requireID(),
                            createdAt: armoryItem.createdAt,
                            updatedAt: armoryItem.updatedAt,
                            deletedAt: armoryItem.deletedAt),
                        quantity: quantity)
            },
            createdAt: createdLeaseModel.createdAt,
            updatedAt: createdLeaseModel.updatedAt,
            deletedAt: createdLeaseModel.deletedAt
        )
        
//        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .leaseCreated, detailOutput)
        
        let latestLeases = try await  latestLeasesApi(req)
        let dashboardUpdate = Armory.Dashboard.Detail(latestLeases: latestLeases, recentlyAddedItems: nil, latestNews: nil, itemsInArmory: nil, leasedToday: try await leasedTodayApi(req: req))
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .dashboard, dashboardUpdate)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let leaseModel = try await findBy(identifier(req), on: req.db)
        
        // Fetch all lease items associated with this lease
        let leaseItems = try await LeaseItemModel.query(on: req.db)
            .filter(\.$leaseId == leaseModel.requireID())
            .all()
        
        let leaseModelId = try leaseModel.requireID()
        
        // If lease is opened don't delete it. It needs to be closed first and than deleted.
        if !leaseModel.returned { throw ArmoryErrors.leaseDeleteFailed(leaseId: leaseModelId) }
        
        // Start a transaction to ensure atomic updates
//        try await req.db.transaction { db in
            // Restore stock for each armory item based on the quantity in the lease
            for leaseItem in leaseItems {
                guard let armoryItem = try await ArmoryItemModel.find(leaseItem.armoryItemId, on: req.db) else {
                    throw ArmoryErrors.armoryItemNotFound
                }
                
                // Restore the stock count
                armoryItem.inStock += leaseItem.quantity
                
                // Save the updated armory item
                try await armoryItem.save(on: req.db)
                try await armoryItem.$category.load(on: req.db)
                
                let updatedArmoryItem: Armory.Item.Detail = .init(
                    id: try armoryItem.requireID(),
                    name: armoryItem.name,
                    imageKey: armoryItem.imageKey,
                    aboutInfo: armoryItem.aboutInfo,
                    inStock: armoryItem.inStock,
                    category: .init(id: try armoryItem.category.requireID(),
                                    name: armoryItem.category.name),
                    categoryId: try armoryItem.category.requireID(),
                    createdAt: armoryItem.createdAt,
                    updatedAt: armoryItem.updatedAt,
                    deletedAt: armoryItem.deletedAt)
                
                try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, updatedArmoryItem)
//            }
            
            // Delete the lease items
            try await leaseItems.delete(on: req.db)
            
            // Delete the lease itself
            try await leaseModel.delete(on: req.db)
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
        
        let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
        
        return try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
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
        
        if updateObject.returned == leaseModel.returned {
            return try await updateLease(req, leaseModel: leaseModel, updateObject: updateObject)
        } else {
            return updateObject.returned ? try await closeLease(req, leaseModel: leaseModel, updateObject: updateObject) : try await openLease(req, leaseModel: leaseModel, updateObject: updateObject)
        }
    }
    
    func patchApi(_ req: Request) async throws -> DetailObject {
        // Decode the incoming patch request, which may contain optional updates
        let patchObject = try req.content.decode(PatchObject.self)
        
        // Fetch the existing lease, including user and items
        guard let leaseModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.leaseNotFound // Throw an error if the lease does not exist
        }
        
        // If the `items` parameter is provided in the request, update the lease items
        if let items = patchObject.items {
            let updateObject = UpdateObject(
                items: items.map { .init(armoryItemId: $0.armoryItemId, quantity: $0.quantity) },
                returned: leaseModel.returned // Keep the current `returned` state
            )
            return try await updateLease(req, leaseModel: leaseModel, updateObject: updateObject)
        }
        
        // If the `returned` parameter is provided, handle lease closing/opening
        if let returned = patchObject.returned {
            // Prevent redundant updates (e.g., reopening an already open lease)
            if returned == leaseModel.returned {
                throw returned ? ArmoryErrors.leaseAlreadyClosed : ArmoryErrors.leaseAlreadyOpened
            }
            
            let updateObject = UpdateObject(
                items: [], // No item changes, only updating the `returned` status
                returned: returned // Keep the current `returned` state
            )
            
            // If `returned` is true, close the lease; otherwise, reopen it
            return returned ? try await closeLease(req, leaseModel: leaseModel, updateObject: updateObject) : try await openLease(req, leaseModel: leaseModel, updateObject: updateObject)
        }
        
        // If no updates were provided, return the current lease details
        return try await detailApi(req)
    }
    
    func listApi(_ req: Request) async throws -> ListObject {
        let models = try await paginatedList(req,
                                    queryBuilders: { $0.with(\.$user) }
        )
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
            let leaseDetail = try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
            leases.append(leaseDetail)
        }
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
    
    func getUserLeases(_ req: Request) async throws -> ListObject {
        guard let userIdString = req.parameters.get("userId"), let userId = UUID(uuidString: userIdString) else { throw AuthenticationError.userNotFound }
        
        let models = try await paginatedList(req, queryBuilders: {
            $0.sort(\.$returned, .ascending)
                .sort(\.$createdAt, .descending)
                .filter(\.$user.$id == userId)
                .with(\.$user)
        })
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
            let leaseDetail = try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
            leases.append(leaseDetail)
        }
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
    
    func getCurrentUserLeases(_ req: Request) async throws -> ListObject {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        let userId = try user.requireID()
        
        let models = try await paginatedList(req, queryBuilders: {
            $0.sort(\.$returned, .ascending)
                .sort(\.$createdAt, .descending)
                .filter(\.$user.$id == userId)
                .with(\.$user)
        })
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
            let leaseDetail = try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
            leases.append(leaseDetail)
        }
        
        return .init(leases: leases, metadata: .init(page: models.metadata.page, per: models.metadata.per, total: models.metadata.total))
    }
    
    func latestLeasesApi(_ req: Request) async throws -> [DetailObject] {
        guard let twentyFourHoursAgo = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
            throw Abort(.internalServerError, reason: "Failed to calculate date range")
        }
        
        let models = try await paginatedList(req, queryBuilders: {
            $0.sort(\.$returned, .ascending)
                .sort(\.$createdAt, .descending)
                .filter(\.$createdAt >= twentyFourHoursAgo)
                .with(\.$user)
        })
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
            let leaseDetail = try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
            leases.append(leaseDetail)
        }
        
        return leases
    }
    
    func getAllActiveLeasesApi(_ req: Request) async throws -> [DetailObject] {
        let models = try await paginatedList(req, queryBuilders: {
            $0.sort(\.$createdAt, .descending)
                .filter(\.$returned == false)
                .with(\.$user)
        })
        
        var leases: [Armory.Lease.Detail] = []
        
        for leaseModel in models.items {
            let armoryItemsWithQuantities = try await fetchArmoryItemsForLease(leaseModel: leaseModel, req: req)
            let leaseDetail = try await mapLeaseDetail(leaseModel: leaseModel, armoryItemsWithQuantities: armoryItemsWithQuantities, req: req)
            leases.append(leaseDetail)
        }
        
        return leases
    }
    
    func leasedTodayApi(req: Request) async throws -> Int {
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        return try await LeaseModel.query(on: req.db)
            .filter(\.$createdAt >= todayStart)
            .count()
    }
}
