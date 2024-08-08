//
//  ValidationAbort.swift
//  
//
//  Created by Mico Miloloza on 10.07.2023..
//

import Vapor


public struct ValidationAbort: AbortError {
    public var abort: Abort
    public var message: String?
    public var details: [ValidationErrorDetail]
    
    public var status: HTTPStatus { abort.status }
    public var reason: String { abort.reason }
    
    public init(abort: Abort, message: String? = nil, details: [ValidationErrorDetail]) {
        self.abort = abort
        self.message = message
        self.details = details
    }
 }
