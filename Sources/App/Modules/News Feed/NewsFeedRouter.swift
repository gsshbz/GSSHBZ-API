//
//  NewsFeedRouter.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Vapor


public struct NewsFeedRouter: RouteCollection {
    let newsFeedApiController = NewsFeedApiController()
    
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        newsFeedApiController.setupRoutes(api)
    }
}
