//
//  SecurityHeadersMiddleware.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 09.04.2025..
//
import Vapor
import Fluent


struct SecurityHeadersMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        
        // Add security headers
        response.headers.add(name: .xFrameOptions, value: "DENY")
        response.headers.add(name: .xContentTypeOptions, value: "nosniff")
        response.headers.add(name: "X-XSS-Protection", value: "1; mode=block")
        response.headers.add(name: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains")
        response.headers.add(name: "Content-Security-Policy", value: "default-src 'self'")
        
        return response
    }
}
