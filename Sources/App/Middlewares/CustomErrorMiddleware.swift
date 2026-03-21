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

            if let validationError = error as? ValidationsError {
                status = validationError.status
                // Izvuci identifier iz prvog failure-a
                identifier = Self.identifierFromValidationError(validationError)
                reason = validationError.reason
            } else if let abortError = error as? AbortError {
                status = abortError.status
                identifier = (abortError as? AppError)?.identifier ?? "unknown_error"
                reason = abortError.reason
            } else {
                status = .internalServerError
                identifier = "internal_server_error"
                reason = "An internal server error occurred"
                
                request.logger.error("Internal server error to investigate: \(error)")
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
    
    // Maps ValidationFailure on identifier
    private static func identifierFromValidationError(_ error: ValidationsError) -> String {
        guard let failure = error.failures.first else {
            return "validation_error"
        }
        
        let field = failure.key.stringValue  // npr. "email", "password"
        let description = failure.result.failureDescription ?? ""
        
        // Mapiraj po fieldu i tipu greške
        switch field {
        case "email":
            return "invalid_email"
        case "password":
            if description.contains("at least") {
                return "password_too_short"
            }
            return "invalid_password"
        case "username":
            return "invalid_username"
        default:
            return "invalid_\(field)"  // fallback: "invalid_phoneNumber" itd.
        }
    }
}
