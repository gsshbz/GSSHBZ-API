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
        
        if let futureArmoryItem = try await ArmoryItemModel.query(on: req.db).filter(\.$name == input.name).first() {
            throw ArmoryErrors.duplicateItemName(futureArmoryItem.name)
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw ArmoryErrors.categoryNotFound
        }
        
        // Get the `Public` directory path
        let assetsDirectory = req.application.directory.publicDirectory + "img/"
        
        // Generate a unique file name for the image
        let fileExtension = input.image.filename.split(separator: ".").last ?? "jpg"
        let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
        
        // Full path where the image will be saved
        let filePath = assetsDirectory + uniqueFileName
        
        // Save the image data to the specified path
        try await req.fileio.writeFile(input.image.data, at: filePath)
        
        let armoryModel = ArmoryItemModel(name: input.name, imageKey: uniqueFileName, aboutInfo: input.aboutInfo, categoryId: input.categoryId ?? defaultCategory.id!)
        
        try await armoryModel.save(on: req.db)
        try await armoryModel.$category.load(on: req.db)
        
        return  .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
    }
    
    func detailApi(_ req: Request) async throws -> Armory.Item.Detail {
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .with(\.$category)
            .first() else {
            throw ArmoryErrors.armoryItemNotFound
        }
        
        return .init(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
    }
    
    func updateApi(_ req: Request) async throws -> Armory.Item.Detail {
        let input = try req.content.decode(UpdateObject.self)
        
        guard let armoryModel = try await ArmoryItemModel.query(on: req.db)
            .filter(\.$id == identifier(req))
            .with(\.$category)
            .first() else {
            throw Abort(.notFound)
        }
        
        guard let defaultCategory = try await ArmoryCategoryModel.query(on: req.db)
            .filter(\.$name == "Default")
            .first() else {
            throw Abort(.notFound)
        }
        
        // Get the `Public` directory path
        let assetsDirectory = req.application.directory.publicDirectory + "img/"
        
        // Generate a unique file name for the image
        let fileExtension = input.image.filename.split(separator: ".").last ?? "jpg"
        let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"
        
        // Full path where the image will be saved
        let filePath = assetsDirectory + uniqueFileName
        
        // Save the image data to the specified path
        try await req.fileio.writeFile(input.image.data, at: filePath)
        
        armoryModel.name = input.name
        armoryModel.imageKey = uniqueFileName
        armoryModel.aboutInfo = input.aboutInfo
        armoryModel.inStock = input.inStock
        armoryModel.$category.id = input.categoryId ?? defaultCategory.id!
        
        try await armoryModel.update(on: req.db)
        
        let armoryItem = Armory.Item.Detail(id: try armoryModel.requireID(), name: armoryModel.name, imageKey: armoryModel.imageKey, aboutInfo: armoryModel.aboutInfo, inStock: armoryModel.inStock, category: .init(id: try armoryModel.category.requireID(), name: armoryModel.category.name), categoryId: try armoryModel.category.requireID())
        
        return armoryItem
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        .noContent
    }
}
