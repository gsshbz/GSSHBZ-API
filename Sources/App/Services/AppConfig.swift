//
//  AppConfig.swift
//  
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor


struct AppConfig {
    let frontendUrl: String
    let apiUrl: String
    let noReplyEmail: String
    
    static var environment: AppConfig {
        guard
            let frontendUrl = Environment.get("SITE_FRONTEND_URL"),
            let apiUrl = Environment.get("API_URL"),
            let noReplyEmail = Environment.get("NO_REPLY_EMAIL")
        else {
            fatalError("Please add app configuration to environment variables")
        }
        
        return .init(frontendUrl: frontendUrl, apiUrl: apiUrl, noReplyEmail: noReplyEmail)
    }
}


extension Application {
    struct AppConfigKey: StorageKey {
        typealias Value = AppConfig
    }
    
    var config: AppConfig {
        get {
            storage[AppConfigKey.self] ?? .environment
        } set {
            storage[AppConfigKey.self] = newValue
        }
    }
}
