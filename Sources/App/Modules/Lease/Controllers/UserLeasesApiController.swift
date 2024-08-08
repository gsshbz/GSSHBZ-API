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
    
//    var modelName: Name = .init(singular: "accessory", plural: "accessories")
    var parameterId: String = "leaseId"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.PUT, use: updateApi)
        existingModelRoutes.on(.PATCH, use: patchApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
    
    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [Armory.Lease.List] {
        try models.map { model in
                .init(id: model.id!,
                      user: .init(id: try model.user.requireID(),
                                  username: model.user.username),
                      armoryItems: model.armoryItems.map { .init(id: $0.id!,
                                                                 name: $0.name,
                                                                 imageKey: $0.imageKey,
                                                                 aboutInfo: $0.aboutInfo,
                                                                 inStock: $0.inStock,
                                                                 category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) })
        }
    }
    
    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> Armory.Lease.Detail {
            return .init(id: model.id!, user: .init(id: try model.user.requireID(),
                                                    username: model.user.username),
                         armoryItems: model.armoryItems.map { .init(id: $0.id!,
                                                                    name: $0.name,
                                                                    imageKey: $0.imageKey,
                                                                    aboutInfo: $0.aboutInfo,
                                                                    inStock: $0.inStock,
                                                                    category: $0.category != nil ? .init(id: $0.category!.id!, name: $0.category!.name) : nil) })
    }
    
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Lease.Create) async throws {
        
    }
    
    func updateInput(_ req: Request, _ model: DatabaseModel, _ input: Armory.Lease.Update) async throws {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        input.armoryItemsIds.forEach { itemId in
            
        }
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
    
    func createNewLease(_ req: Request) async throws -> Armory.Lease.Detail {
        let jwtUser = try req.auth.require(JWTUser.self)
        let input = try req.content.decode(Armory.Lease.Create.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db), let userId = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        let leaseModel = try LeaseModel(userId: userId)
        try await leaseModel.save(on: req.db)
        
        
        
        let leaseItems = try input.armoryItemsIds.map { itemId in
            return LeaseItemModel(leaseId: try leaseModel.requireID(), armoryItemId: itemId)
        }
        
        try await leaseItems.create(on: req.db)
        
        guard let createdLeaseModel = try await LeaseModel.query(on: req.db)
            .filter(\.$id == leaseModel.requireID())
            .with(\.$user)
            .with(\.$armoryItems)
            .first() else { throw Abort(.badRequest)}
        
        return try await detailOutput(req, createdLeaseModel)
    }
}


extension UserLeasesApiController {
    func createApi(_ req: Request) async throws -> Response {
        let input = try req.content.decode(CreateObject.self)
        let model = DatabaseModel()
        try await createInput(req, model, input)
        try await model.create(on: req.db)
        return try await createResponse(req, model)
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        try await model.delete(on: req.db)
        return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        let model = try await findBy(identifier(req), on: req.db)
        return try await detailOutput(req, model)
    }
    
    func patchApi(_ req: Request) async throws -> Response {
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(PatchObject.self)
        try await patchInput(req, model, input)
        try await model.update(on: req.db)
        return try await patchResponse(req, model)
    }
    
    func updateApi(_ req: Request) async throws -> Response {
        let model = try await findBy(identifier(req), on: req.db)
        let input = try req.content.decode(UpdateObject.self)
        try await updateInput(req, model, input)
        try await model.update(on: req.db)
        return try await updateResponse(req, model)
    }
    
    func listApi(_ req: Request) async throws -> [ListObject] {
        let models = try await list(req,
                                    queryBuilders: { $0.with(\.$user) },
                                    { $0.with(\.$armoryItems) }
        )
        
        return try await listOutput(req, models)
    }
}
