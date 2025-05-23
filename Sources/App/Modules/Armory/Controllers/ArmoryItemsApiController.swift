//
//  ArmoryItemsApiController.swift
//
//
//  Created by Mico Miloloza on 27.12.2023..
//

import Vapor
import Fluent


extension Armory.Item.List: Content {}
extension Armory.Item.Detail: Content {}
extension Armory.Item.Create: Content {}

struct ArmoryItemsApiController: ListController {
    typealias ApiModel = Armory.Item
    typealias DatabaseModel = ArmoryItemModel
    
    typealias CreateObject = Armory.Item.Create
    typealias UpdateObject = Armory.Item.Update
    typealias DetailObject = Armory.Item.Detail
    typealias PatchObject = Armory.Item.Patch
    typealias ListObject = Armory.Item.List
    
    var modelName: Name = .init(singular: "accessory", plural: "accessories")
    var parameterId: String = "accessoryId"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.POST, use: updateApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
    
    func listApi(_ req: Request) async throws -> [Armory.Item.List] {
        let armoryItems = try await ArmoryItemModel.query(on: req.db)
            .with(\.$category)
            .all()
        
        return try armoryItems.map { model in
                .init(id: model.id!,
                      name: model.name,
                      imageKey: model.imageKey,
                      aboutInfo: model.aboutInfo,
                      inStock: model.inStock,
                      category: .init(id: model.category.id!, name: model.category.name),
                      categoryId: try model.category.requireID(),
                      createdAt: model.createdAt,
                      updatedAt: model.updatedAt,
                      deletedAt: model.deletedAt)
        }
    }
    
    func createApi(_ req: Request) async throws -> Armory.Item.Detail {
        let input = try req.content.decode(CreateObject.self)
        
        if let futureArmoryItem = try await ArmoryItemModel.query(on: req.db).filter(\.$name == input.name).first() {
            throw ArmoryErrors.duplicateArmoryItemName(itemName: futureArmoryItem.name)
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
        if let categoryId = input.categoryId {
            guard let _ = try await ArmoryCategoryModel.query(on: req.db)
                .filter(\.$id == categoryId)
                .first() else {
                throw ArmoryErrors.categoryNotFound
            }
        }
        
//        var publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/default-avatar.jpg"
        
//        if let image = input.image {
//            // Validate MIME type
//            guard ["image/jpeg", "image/png"].contains(image.contentType?.description) else {
//                throw Abort(.unsupportedMediaType, reason: "Only JPEG and PNG images are allowed.")
//            }
//            // Get the `Public` directory path
//            let assetsDirectory = req.application.directory.publicDirectory + "img/"
//            
//            // Generate a unique file name for the image
//            let fileExtension = image.filename.split(separator: ".").last ?? "jpg"
//            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
//            
//            // Full path where the image will be saved
//            let filePath = assetsDirectory + uniqueFileName
//            
//            // Save the image data to the specified path
//            try await req.fileio.writeFile(image.data, at: filePath)
//
//            publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/\(uniqueFileName)"
//        }
        
        if input.inStock < 0 {
            throw ArmoryErrors.armoryItemQuantityNotSufficient
        }
        
        let armoryModel = ArmoryItemModel(name: input.name, imageKey: input.imageKey ?? "0", aboutInfo: input.aboutInfo, categoryId: input.categoryId ?? defaultCategory.id!, inStock: input.inStock)
        
        try await armoryModel.save(on: req.db)
        try await armoryModel.$category.load(on: req.db)
        
        let armoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID(),
                                            createdAt: armoryModel.createdAt,
                                            updatedAt: armoryModel.updatedAt,
                                            deletedAt: armoryModel.deletedAt)
        
        let socketArmoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: nil,
                                                  createdAt: armoryModel.createdAt,
                                                  updatedAt: armoryModel.updatedAt,
                                                  deletedAt: armoryModel.deletedAt)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemCreated, socketArmoryItem)
        
        let recentlyAddedItems = try await  recentlyAddedItemsApi(req: req)
        let dashboardUpdate = Armory.Dashboard.Detail(latestLeases: nil, recentlyAddedItems: recentlyAddedItems, latestNews: nil, itemsInArmory: try await totalItemsApi(req: req), leasedToday: nil)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .dashboard, dashboardUpdate)
        
        return  armoryItem
    }
    
    func detailApi(_ req: Request) async throws -> Armory.Item.Detail {
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .with(\.$category)
            .first() else {
            throw ArmoryErrors.armoryItemNotFound
        }
        
        return .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID(),
                     createdAt: armoryModel.createdAt,
                     updatedAt: armoryModel.updatedAt,
                     deletedAt: armoryModel.deletedAt)
    }
    
    func updateApi(_ req: Request) async throws -> Armory.Item.Detail {
        let input = try req.content.decode(UpdateObject.self)
        
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .with(\.$category)
            .first() else {
            throw ArmoryErrors.armoryItemNotFound
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
//        var shouldUpdateImage: Bool = false
//        var publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/default-avatar.jpg"
        
        // MARK: - Image upload code, currently not in use. Icons will be added in frontend project locally and server will save only their name string values
//        if let image = input.image {
//            // Validate MIME type
//            guard ["image/jpeg", "image/png"].contains(image.contentType?.description) else {
//                throw Abort(.unsupportedMediaType, reason: "Only JPEG and PNG images are allowed.")
//            }
//            
//            shouldUpdateImage = true
//            // Get the `Public` directory path
//            let assetsDirectory = req.application.directory.publicDirectory + "img/"
//            
//            // Generate a unique file name for the image
//            let fileExtension = image.filename.split(separator: ".").last ?? "jpg"
//            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
//            
//            // Full path where the image will be saved
//            let filePath = assetsDirectory + uniqueFileName
//            
//            // Save the image data to the specified path
//            try await req.fileio.writeFile(image.data, at: filePath)
//            
//            shouldUpdateImage = true
//            publicImageUrl = "\(AppConfig.environment.frontendUrl)/img/\(uniqueFileName)"
//        }
        
        armoryModel.name = input.name ?? armoryModel.name
        armoryModel.imageKey = /*shouldUpdateImage ? publicImageUrl : */ input.imageKey ?? armoryModel.imageKey
        armoryModel.aboutInfo = input.aboutInfo ?? armoryModel.aboutInfo
        if let inStock = input.inStock, inStock < 0 {
            throw ArmoryErrors.armoryItemQuantityNotSufficient
        }
        armoryModel.inStock = input.inStock ?? armoryModel.inStock
        armoryModel.$category.id = input.categoryId ?? armoryModel.$category.id
        
        try await armoryModel.update(on: req.db)
        try await armoryModel.$category.load(on: req.db)
        
        let armoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID(),
                                            createdAt: armoryModel.createdAt,
                                            updatedAt: armoryModel.updatedAt,
                                            deletedAt: armoryModel.deletedAt)
        
        let socketArmoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: nil,
                                                  createdAt: armoryModel.createdAt,
                                                  updatedAt: armoryModel.updatedAt,
                                                  deletedAt: armoryModel.deletedAt)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, socketArmoryItem)
        
        return armoryItem
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .with(\.$category)
            .first() else {
            throw ArmoryErrors.armoryItemNotFound
        }
        
        let armoryModelId = try armoryModel.requireID()
        
        // 🔍 Check if the item is in any open leases
        let hasOpenLeases = try await LeaseItemModel.query(on: req.db)
            .join(LeaseModel.self, on: \LeaseItemModel.$leaseId == \LeaseModel.$id)
            .filter(LeaseItemModel.self, \.$armoryItemId == armoryModelId)
            .filter(LeaseModel.self, \.$returned == false) // Adjust this based on how you track open leases
            .first() != nil
        
        if hasOpenLeases {
            throw ArmoryErrors.notAllItemsReturned
        }
        
        do {
            try await armoryModel.delete(on: req.db)
        } catch {
            throw ArmoryErrors.armoryItemDeleteFailed(itemName: armoryModel.name)
        }
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemDeleted, armoryModelId)
        
        return .noContent
    }
    
    /// Fetches the 5 most recently added armory items.
    func recentlyAddedItemsApi(req: Request) async throws -> [Armory.Item.List] {
        let armoryItems = try await ArmoryItemModel.query(on: req.db)
            .with(\.$category)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
        
        return try armoryItems.map { model in
                .init(id: model.id!,
                      name: model.name,
                      imageKey: model.imageKey,
                      aboutInfo: model.aboutInfo,
                      inStock: model.inStock,
                      category: .init(id: model.category.id!, name: model.category.name),
                      categoryId: try model.category.requireID(),
                      createdAt: model.createdAt,
                      updatedAt: model.updatedAt,
                      deletedAt: model.deletedAt)
        }
    }

    /// Fetches the total number of armory items.
    func totalItemsApi(req: Request) async throws -> Int {
        return try await ArmoryItemModel.query(on: req.db).count()
    }
}
