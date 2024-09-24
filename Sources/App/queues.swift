//
//  queues.swift
//
//
//  Created by Mico Miloloza on 04.09.2024..
//

import Vapor
import Queues


func queues(_ app: Application) throws {
    // MARK: Queues Configuration
    if app.environment != .testing {
        try app.queues.use(
            .redis(url:
                Environment.get("REDIS_HOST") ?? "redis://localhost:6379"
            )
        )
    }
    
    // MARK: Jobs
    app.queues.add(EmailJob())
}
