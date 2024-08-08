//
//  ApiController.swift
//
//
//  Created by Mico Miloloza on 27.12.2023..
//

import Vapor


public protocol ApiController: ApiListController,
                               ApiDetailController,
                               ApiCreateController,
                               ApiUpdateController,
                               ApiPatchController,
                               ApiDeleteController {
}

public extension ApiController {
    func createResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(status: .created, for: req)
    }
    
    func updateResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func patchResponse(_ req: Request, _ model: DatabaseModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(routes)
        setupPatchRoutes(routes)
        setupDeleteRoutes(routes)
    }
    
//    func leaseAccessories(_ req: Request) async throws -> Response {
//        let model = try await findBy(identifier(req), on: req.db)
//        
//        return 
//    }
}
