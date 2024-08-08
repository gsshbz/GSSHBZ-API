//
//  ArmoryAccessoryApiController.swift
//
//
//  Created by Mico Miloloza on 27.12.2023..
//

import Vapor


extension Armory.Item.List: Content {}
extension Armory.Item.Detail: Content {}

struct ArmoryItemsApiController: ApiController {
    typealias ApiModel = Armory.Item
    typealias DatabaseModel = ArmoryItemModel
    
    var modelName: Name = .init(singular: "accessory", plural: "accessories")
    var parameterId: String = "accessoryId"
    
    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [Armory.Item.List] {
        models.map { model in
                .init(id: model.id!,
                      name: model.name,
                      imageKey: model.imageKey,
                      aboutInfo: model.aboutInfo,
                      inStock: model.inStock,
                      category: model.category != nil ? .init(id: model.category!.id!, name: model.category!.name) : nil)
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
                         category: category != nil ? .init(id: category!.id!, name: category!.name) : nil)
        } catch {
            print(error)
        }
        
        return .init(id: model.id!, 
                     name: model.name,
                     imageKey: model.imageKey,
                     aboutInfo: model.aboutInfo,
                     inStock: model.inStock,
                     category: nil)
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
