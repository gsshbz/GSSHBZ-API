//
//  ApiDetailController.swift
//
//
//  Created by Mico Miloloza on 13.12.2023..
//

import Vapor


public protocol ApiDetailController: DetailController {
    associatedtype DetailObject: Content
    
    func detailOutput(_ req: Request, _ model: DatabaseModel) async throws -> DetailObject
    func detailApi(_ req: Request) async throws -> DetailObject
    func setupDetailRoutes(_ routes: RoutesBuilder)
}

public extension ApiDetailController {
    func detailApi(_ req: Request) async throws -> DetailObject {
        let model = try await findBy(identifier(req), on: req.db)
        return try await detailOutput(req, model)
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.on(.GET, use: detailApi)
    }
}
