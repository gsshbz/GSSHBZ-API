//
//  ArmoryCategoryApiController.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Vapor
import Fluent


extension Armory.Category.List: Content {}
extension Armory.Category.Detail: Content {}

struct ArmoryCategoryApiController: ListController {
    typealias ApiModel = Armory.Category
    
    // Response Objects
    typealias DatabaseModel = ArmoryCategoryModel
    typealias DetailObject = Armory.Category.Detail
    typealias ListObject = Armory.Category.List
    
    // Request Objects
    typealias CreateObject = Armory.Category.Create
    typealias UpdateObject = Armory.Category.Update
    typealias PatchObject = Armory.Category.Patch
    
    var modelName: Name = .init(singular: "category", plural: "categories")
    var parameterId: String = "categoryId"
    
    var defaultCategoryName = "Default"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.POST, use: updateApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
}

extension ArmoryCategoryApiController {
    func createApi(_ req: Request) async throws -> DetailObject {
        let input = try req.content.decode(CreateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let _ = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        let categoryModel = ArmoryCategoryModel(name: input.name)
        try await categoryModel.save(on: req.db)
        
        let category = DetailObject(id: try categoryModel.requireID(), name: categoryModel.name)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .categoryCreated, category)
        
        return category
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        let categoryId = try model.requireID()
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == defaultCategoryName)
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
        // Fetch affected Armory Items before updating
        //        let affectedItems = try await ArmoryItemModel.query(on: req.db)
        //            .with(\.$category)
        //            .filter(\.$category.$id == categoryId)
        //            .all()
        
        //        try await ArmoryItemModel.query(on: req.db)
        //            .filter(\.$category.$id == categoryId)
        //            .set(\.$category.$id, to: defaultCategory.requireID())
        //            .update()
        
        let armoryModels = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$category.$id == categoryId)
            .with(\.$category)
            .all()
        
        try armoryModels.forEach { $0.$category.id = try defaultCategory.requireID() }
        armoryModels.forEach { let _ = $0.update(on: req.db) }
        
        for armoryModel in armoryModels {
            try await armoryModel.$category.load(on: req.db)
            
            // Frontend doesn't need categoryId parameter in socket update, that's why it is set to nil
            let armoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: nil, createdAt: armoryModel.createdAt, updatedAt: armoryModel.updatedAt, deletedAt: armoryModel.deletedAt)
            
            try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .armoryItemUpdated, armoryItem)
        }
        
        try await model.delete(on: req.db)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .categoryDeleted, categoryId)
        
        return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        guard let categoryModel = try await DatabaseModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
        return .init(id: try categoryModel.requireID(), name: categoryModel.name)
    }
    
    func updateApi(_ req: Request) async throws -> DetailObject {
        let updateObject = try req.content.decode(UpdateObject.self)
        
        guard let categoryModel = try await DatabaseModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
        categoryModel.name = updateObject.name
        
        try await categoryModel.update(on: req.db)
        
        let detailObject = DetailObject(id: try categoryModel.requireID(), name: categoryModel.name)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .categoryUpdated, detailObject)
        
        return detailObject
    }
    
    func listApi(_ req: Request) async throws -> [ListObject] {
        let getList = try? req.query.get(Bool.self, at: "items")
        
        let models: [DatabaseModel]
        
        if let getList, getList {
            models = try await list(req, queryBuilders: { query in
                query.with(\.$armoryItems) { armoryItem in
                    armoryItem.with(\.$category)
                }
            })
        } else {
            // Currently this api call is used only for admins to edit Category name or delete the category that's why default category is not needed
            models = try await list(req, queryBuilders: { $0.filter(\.$name != defaultCategoryName) })
        }
        
        return try models.map { .init(id: try $0.requireID(), name: $0.name, armoryItems: $0.$armoryItems.value == nil ? nil : try $0.armoryItems.map { .init(id: try $0.requireID(), name: $0.name, imageKey: $0.imageKey, aboutInfo: $0.aboutInfo, inStock: $0.inStock, category: .init(id: try $0.category.requireID(), name: $0.category.name), categoryId: try $0.category.requireID(), createdAt: $0.createdAt, updatedAt: $0.updatedAt, deletedAt: $0.deletedAt) }) }    
    }
}
