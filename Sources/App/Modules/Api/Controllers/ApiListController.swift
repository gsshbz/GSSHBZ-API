//
//  ApiListController.swift
//
//
//  Created by Mico Miloloza on 13.12.2023..
//

import Vapor


public protocol ApiListController: ListController {
    associatedtype ListObject: Content
    
    func listOutput(_ req: Request, _ models: [DatabaseModel]) async throws -> [ListObject]
    func listApi(_ req: Request) async throws -> [ListObject]
    func setupListRoutes(_ routes: RoutesBuilder)
}

public extension ApiListController {
    func listApi(_ req: Request) async throws -> [ListObject] {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.on(.GET, use: listApi)
    }
}
