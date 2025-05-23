//
//  ApiDeleteController.swift
//
//
//  Created by Mico Miloloza on 27.12.2023..
//

import Vapor


public protocol ApiDeleteController: DeleteController {
    func deleteApi(_ req: Request) async throws -> HTTPStatus
    func setupDeleteRoutes(_ routes: RoutesBuilder)
}

public extension ApiDeleteController {
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let model = try await findBy(identifier(req), on: req.db)
        try await model.delete(on: req.db)
        return .noContent
    }
    
    func setupDeleteRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
}
