//
//  ListController.swift
//
//
//  Created by Mico Miloloza on 13.12.2023..
//

import Vapor
import Fluent


public protocol ListController: ModelController {
    func list(_ req: Request) async throws -> [DatabaseModel]
    func list(_ req: Request, queryBuilders: (QueryBuilder<DatabaseModel>) -> Void...) async throws -> [DatabaseModel]
}

public extension ListController {
    func list(_ req: Request) async throws -> [DatabaseModel] {
        try await DatabaseModel
            .query(on: req.db)
            .all()
    }
    
    func list(_ req: Request, queryBuilders: (QueryBuilder<DatabaseModel>) -> Void...) async throws -> [DatabaseModel] {
        let query = DatabaseModel.query(on: req.db)
        
        queryBuilders.forEach { $0(query) }
        
        return try await query.all()
    }
}
