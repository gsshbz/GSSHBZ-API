//
//  AuthenticationError.swift
//  
//
//  Created by Mico Miloloza on 13.02.2024..
//

import Vapor


enum AuthenticationError: AppError {
    case passwordsDontMatch
    case emailAlreadyExists
    case invalidEmailOrPassword
    case refreshTokenOrUserNotFound
    case refreshTokenHasExpired
    case userNotFound
    case emailTokenHasExpired
    case emailTokenNotFound
    case emailNotVerified
    case invalidPasswordToken
    case passwordTokenHasExpired
    case missingRegistrationToken
    case registrationTokenNotValid
    case registrationTokenHasExpired
    case multipleValidationFailures([(field: String, identifier: String)]) // For when multiple fields fail
    case invalidField(String) // For other validation failures
    case specificError(identifier: String, reason: String, status: HTTPResponseStatus = .badRequest)
}

extension AuthenticationError: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .passwordsDontMatch:
            return .badRequest
        case .emailAlreadyExists:
            return .badRequest
        case .emailTokenHasExpired:
            return .badRequest
        case .invalidEmailOrPassword:
            return .badRequest
        case .refreshTokenOrUserNotFound:
            return .notFound
        case .userNotFound:
            return .notFound
        case .emailTokenNotFound:
            return .notFound
        case .refreshTokenHasExpired:
            return .unauthorized
        case .emailNotVerified:
            return .unauthorized
        case .invalidPasswordToken:
            return .notFound
        case .passwordTokenHasExpired:
            return .unauthorized
        case .missingRegistrationToken:
            return .badRequest
        case .registrationTokenNotValid:
            return .badRequest
        case .registrationTokenHasExpired:
            return .badRequest
        case .multipleValidationFailures(_):
            return .badRequest
        case .invalidField(_):
            return .badRequest
        case .specificError(_, _, let status):
            return status
        }
    }
    
    var reason: String {
        switch self {
        case .passwordsDontMatch:
            return "Passwords do not match"
        case .emailAlreadyExists:
            return "A user with that email already exists"
        case .invalidEmailOrPassword:
            return "Email or password is incorrect"
        case .refreshTokenOrUserNotFound:
            return "User or refresh token was not found"
        case .refreshTokenHasExpired:
            return "Refresh token has expired"
        case .userNotFound:
            return "User was not found"
        case .emailTokenNotFound:
            return "Email token not found"
        case .emailTokenHasExpired:
            return "Email token has expired"
        case .emailNotVerified:
            return "Email is not verified"
        case .invalidPasswordToken:
            return "Invalid reset password token"
        case .passwordTokenHasExpired:
            return "Reset password token has expired"
        case .missingRegistrationToken:
            return "Registration token is required"
        case .registrationTokenNotValid:
            return "Registration token is not valid"
        case .registrationTokenHasExpired:
            return "Registration token has expired"
        case .multipleValidationFailures(let failures):
            let fields = failures.map { $0.field }
            return "Validation failed for fields: \(fields.joined(separator: ", "))"
        case .invalidField(let field):
            return "Validation failed for field: \(field)"
        case .specificError(_, let reason, _):
            return reason
        }
    }
    
    var identifier: String {
        switch self {
        case .passwordsDontMatch:
            return "passwords_dont_match"
        case .emailAlreadyExists:
            return "email_already_exists"
        case .invalidEmailOrPassword:
            return "invalid_email_or_password"
        case .refreshTokenOrUserNotFound:
            return "refresh_token_or_user_not_found"
        case .refreshTokenHasExpired:
            return "refresh_token_has_expired"
        case .userNotFound:
            return "user_not_found"
        case .emailTokenNotFound:
            return "email_token_not_found"
        case .emailTokenHasExpired:
            return "email_token_has_expired"
        case .emailNotVerified:
            return "email_is_not_verified"
        case .invalidPasswordToken:
            return "invalid_password_token"
        case .passwordTokenHasExpired:
            return "password_token_has_expired"
        case .missingRegistrationToken:
            return "missing_registration_token"
        case .registrationTokenNotValid:
            return "registration_token_not_valid"
        case .registrationTokenHasExpired:
            return "registration_token_has_expired"
        case .multipleValidationFailures(let failures):
            let identifiers = failures.map { $0.identifier }
            return "\(identifiers.joined(separator: "&"))"
        case .invalidField(let field):
            return "invalid_\(field)"
        case .specificError(let identifier, _, _):
            return identifier
        }
    }
}
