//
//  ModelController.swift
//
//
//  Created by Mico Miloloza on 11.10.2023..
//

import Vapor
import Fluent


public struct Name {
    let singular: String
    let plural: String
    
    init(singular: String, plural: String? = nil) {
        self.singular = singular
        self.plural = plural ?? singular + "s"
    }
}


public protocol ModelController {
    associatedtype ApiModel: ApiModelInterface
    associatedtype DatabaseModel: DatabaseModelInterface
    
    static var moduleName: String { get }
    static var modelName: Name { get }
    
    func identifier(_ req: Request) throws -> UUID
    func findBy(_ id: UUID, on db: Database) async throws -> DatabaseModel
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder
}

extension ModelController {
    static var moduleName: String {
        DatabaseModel.Module.identifier.capitalized
    }
    
    static var modelName: Name {
        .init(singular: String(DatabaseModel.identifier.dropLast(1)))
    }
    
    func identifier(_ req: Request) throws -> UUID {
        guard let id = req.parameters.get(ApiModel.pathIdKey),
              let uuid = UUID(uuidString: id)
        else {
            throw Abort(.badRequest)
        }
        
        return uuid
    }
    
    func findBy(_ id: UUID, on db: Database) async throws -> DatabaseModel {
        guard let model = try await DatabaseModel.find(id, on: db) else {
            throw Abort(.notFound)
        }
        
        return model
    }
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes
            .grouped(ApiModel.Module.pathKey.pathComponents)
            .grouped(ApiModel.pathKey.pathComponents)
    }
}
