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
//    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
//        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
//    }
    
//    func updateResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
//        try await detailOutput(req, model).encodeResponse(for: req)
//    }
//    
//    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
//        try await detailOutput(req, model).encodeResponse(for: req)
//    }
    
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
        existingModelRoutes.on(.PUT, use: updateApi)
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
                      categoryId: try model.category.requireID())
        }
    }
    
    func createApi(_ req: Request) async throws -> Armory.Item.Detail {
        let input = try req.content.decode(CreateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let userId = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw Abort(.notFound)
        }
        
        let armoryModel = ArmoryItemModel(name: input.name, imageKey: input.imageKey, aboutInfo: input.aboutInfo, categoryId: input.categoryId ?? defaultCategory.id!)
        
        return  .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
    }
    
    func detailApi(_ req: Request) async throws -> Armory.Item.Detail {
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .with(\.$category)
            .first() else {
            throw Abort(.notFound)
        }
        
        return .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
    }
    
    func updateApi(_ req: Request) async throws -> Armory.Item.Detail {
        let input = try req.content.decode(UpdateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .with(\.$category)
            .first() else {
            throw Abort(.notFound)
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw Abort(.notFound)
        }
        
        armoryModel.name = input.name
        armoryModel.imageKey = input.imageKey
        armoryModel.aboutInfo = input.aboutInfo
        armoryModel.inStock = input.inStock
        armoryModel.$category.id = input.categoryId ?? defaultCategory.id!
        
        try await armoryModel.update(on: req.db)
        
        return .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        .noContent
    }
    
//    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> Armory.Item.Detail {
//        do {
//            let category = try await model.$category.query(on: req.db).first()
//            
//            return .init(id: model.id!,
//                         name: model.name,
//                         imageKey: model.imageKey,
//                         aboutInfo: model.aboutInfo,
//                         inStock: model.inStock,
//                         category: .init(id: category.id!, name: category.name),
//                         categoryId: try category.requireID())
//        } catch {
//            print(error)
//            
//        }
//    }
//    
//    func createInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Create) async throws {
//        model.name = input.name
//        model.imageKey = input.imageKey
//        model.aboutInfo = input.aboutInfo
//        model.inStock = input.inStock
//        model.$category.id = input.categoryId
//    }
//    
//    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Update) async throws {
//        model.name = input.name
//        model.imageKey = input.imageKey
//        model.aboutInfo = input.aboutInfo
//        model.inStock = input.inStock
//        model.$category.id = input.categoryId
//    }
//    
//    func patchInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Patch) async throws {
//        model.name = input.name ?? model.name
//        model.imageKey = input.imageKey ?? model.imageKey
//        model.aboutInfo = input.aboutInfo ?? model.aboutInfo
//        model.inStock = input.inStock ?? model.inStock
//        model.$category.id = input.categoryId ?? model.$category.id
//    }
}
