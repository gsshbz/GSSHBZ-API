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
    case multipleValidationFailures([String]) // For when multiple fields fail
    case invalidField(String) // For other validation failures
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
        case .multipleValidationFailures(_):
            return .badRequest
        case .invalidField(_):
            return .badRequest
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
        case .multipleValidationFailures(let fields):
            return "Validation failed for fields: \(fields.joined(separator: ", "))"
        case .invalidField(let field):
            return "Validation failed for field: \(field)"
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
        case .multipleValidationFailures:
            return "validation_errors"
        case .invalidField(let field):
            return "invalid_\(field)"
        }
    }
}
