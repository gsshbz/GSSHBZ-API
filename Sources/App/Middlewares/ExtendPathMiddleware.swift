//
//  ExtendPathMiddleware.swift
//  
//
//  Created by Mico Miloloza on 13.06.2023..
//

import Vapor



struct ExtendPathMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if !request.url.path.hasSuffix("/") && !request.url.path.contains(".") {
            return request.redirect(to: request.url.path + "/", redirectType: .permanent)
        }
        
        return try await next.respond(to: request)
    }
}
