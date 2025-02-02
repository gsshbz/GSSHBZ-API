//
//  CustomErrorMiddleware.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 29.01.2025..
//
import Vapor


struct CustomErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapError { error in
            let status: HTTPResponseStatus
            let identifier: String
            let reason: String

            if let abortError = error as? AbortError {
                status = abortError.status
                identifier = (abortError as? AppError)?.identifier ?? "unknown_error"
                reason = abortError.reason
            } else {
                status = .internalServerError
                identifier = "internal_server_error"
                reason = "An internal server error occurred"
            }

            let errorResponse = ErrorResponse(identifier: identifier, status: status.code, reason: reason)
            let response = Response(status: status)
            do {
                try response.content.encode(errorResponse)
            } catch {
                request.logger.error("Failed to encode error response: \(error)")
            }
            return request.eventLoop.makeSucceededFuture(response)
        }
    }
}
