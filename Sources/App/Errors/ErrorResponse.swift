//
//  ErrorResponse.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 29.01.2025..
//
import Vapor


struct ErrorResponse: Content {
    let identifier: String
    let status: UInt
    let reason: String
}
