//
//  ArmoryCategoryApiController.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Vapor


extension Armory.Category.List: Content {}
extension Armory.Category.Detail: Content {}

struct ArmoryCategoryApiController: ApiController {
    typealias ApiModel = Armory.Category
    typealias DatabaseModel = ArmoryCategoryModel
    
    var modelName: Name = .init(singular: "category", plural: "categories")
    var parameterId: String = "categoryId"
    
    // MARK: - Model manipulation methods
    
    // MARK: - List
    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [Armory.Category.List] {
        models.map {
            .init(id: $0.id!, name: $0.name)
        }
    }
    
    // MARK: - Detail
    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> Armory.Category.Detail {
        return .init(id: model.id!, name: model.name)
    }
    
    // MARK: - Create
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Category.Create) async throws {
        model.name = input.name
    }
    
    // MARK: - Update
    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Category.Update) async throws {
        model.name = input.name
    }
    
    // MARK: - Patch
    func patchInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Category.Patch) async throws {
        model.name = input.name ?? model.name
    }
}
