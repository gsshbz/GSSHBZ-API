//
//  AsyncValidator.swift
//  
//
//  Created by Mico Miloloza on 10.07.2023..
//

import Vapor


public protocol AsyncValidator {
    var key: String { get }
    var message: String { get }
    
    /**
     Please note that this function can throw, but we're only going to throw an error if a system
     error happened, such as a database failure or something similar. We always return user-
     related errors as a ValidationErrorDetail object or a nil value if everything was fine.
     */
    func validate(_ req: Request) async throws -> ValidationErrorDetail?
}


public extension AsyncValidator {
    var error: ValidationErrorDetail {
        return .init(key: key, message: message)
    }
}
