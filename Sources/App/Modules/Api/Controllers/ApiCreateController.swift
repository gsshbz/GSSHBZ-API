//
//  ApiCreateController.swift
//
//
//  Created by Mico Miloloza on 13.12.2023..
//

import Vapor


public protocol ApiCreateController: CreateController {
    associatedtype CreateObject: Decodable
    
    func createInput(_ req: Request, _ model: DatabaseModel, _ input: CreateObject) async throws
    func createApi(_ req: Request) async throws -> Response
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response
    func setupCreateRoutes(_ routes: RoutesBuilder)
}

public extension ApiCreateController {
    func createApi(_ req: Request) async throws -> Response {
        let input = try req.content.decode(CreateObject.self)
        let model = DatabaseModel()
        try await createInput(req, model, input)
        try await model.create(on: req.db)
        return try await createResponse(req, model)
    }
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.on(.POST, use: createApi)
    }
}
