//
//  AppError.swift
//  
//
//  Created by Mico Miloloza on 13.02.2024..
//

import Vapor


protocol AppError: AbortError, DebuggableError {}

extension AppError {
    func abort() -> Abort {
        return Abort(self.status, reason: self.reason, identifier: self.identifier)
    }
}
