//
//  Services.swift
//
//
//  Created by Mico Miloloza on 04.09.2024..
//

import Vapor


func services(_ app: Application) throws {
    app.randomGenerators.use(.random)
    app.repositories.use(.database)
}
