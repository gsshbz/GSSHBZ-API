//
//  VehiclesRouter.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 16.09.2025..
//

import Vapor


public struct VehiclesRouter: RouteCollection {
    let vehiclesApiController = VehiclesApiController()
    
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        vehiclesApiController.setupRoutes(api)
    }
}
