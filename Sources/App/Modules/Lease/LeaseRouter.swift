//
//  LeaseRouter.swift
//
//
//  Created by Mico Miloloza on 14.06.2024..
//

import Vapor


public struct LeaseRouter: RouteCollection {
    let armoryLeasesController = UserLeasesApiController()
    
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        armoryLeasesController.setupRoutes(api)
    }
}
