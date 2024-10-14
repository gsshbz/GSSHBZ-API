//
//  ArmoryItemsApiController.swift
//
//
//  Created by Mico Miloloza on 27.12.2023..
//

import Vapor


extension Armory.Item.List: Content {}
extension Armory.Item.Detail: Content {}
#warning("This needs to be refactored as soon as possible")
struct ArmoryItemsApiController: ApiDetailController, ApiCreateController, ApiUpdateController, ApiPatchController, ApiDeleteController {
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    typealias ApiModel = Armory.Item
    typealias DatabaseModel = ArmoryItemModel
    
    var modelName: Name = .init(singular: "accessory", plural: "accessories")
    var parameterId: String = "accessoryId"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
    
//    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [Armory.Item.List] {
//        try models.map { model in
//                .init(id: model.id!,
//                      name: model.name,
//                      imageKey: model.imageKey,
//                      aboutInfo: model.aboutInfo,
//                      inStock: model.inStock,
//                      category: model.category != nil ? .init(id: model.category!.id!, name: model.category!.name) : nil,
//                      categoryId: try model.category?.requireID())
//        }
//    }
//    
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
                      category: model.category != nil ? .init(id: model.category!.id!, name: model.category!.name) : nil,
                      categoryId: try model.category?.requireID())
        }
    }
    
    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> Armory.Item.Detail {
        do {
            let category = try await model.$category.query(on: req.db).first()
            
            return .init(id: model.id!,
                         name: model.name,
                         imageKey: model.imageKey,
                         aboutInfo: model.aboutInfo,
                         inStock: model.inStock,
                         category: category != nil ? .init(id: category!.id!, name: category!.name) : nil,
                         categoryId: try category?.requireID())
        } catch {
            print(error)
        }
        
        return .init(id: model.id!, 
                     name: model.name,
                     imageKey: model.imageKey,
                     aboutInfo: model.aboutInfo,
                     inStock: model.inStock,
                     category: nil,
                     categoryId: try model.category?.requireID())
    }
    
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Create) async throws {
        model.name = input.name
        model.imageKey = input.imageKey
        model.aboutInfo = input.aboutInfo
        model.inStock = input.inStock
        model.$category.id = input.categoryId
    }
    
    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Update) async throws {
        model.name = input.name
        model.imageKey = input.imageKey
        model.aboutInfo = input.aboutInfo
        model.inStock = input.inStock
        model.$category.id = input.categoryId
    }
    
    func patchInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Item.Patch) async throws {
        model.name = input.name ?? model.name
        model.imageKey = input.imageKey ?? model.imageKey
        model.aboutInfo = input.aboutInfo ?? model.aboutInfo
        model.inStock = input.inStock ?? model.inStock
        model.$category.id = input.categoryId ?? model.$category.id
    }
}
