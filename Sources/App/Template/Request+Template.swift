//
//  Request+Template.swift
//  
//
//  Created by Mico Miloloza on 31.05.2023..
//

import Vapor

public extension Request {
    var templates: TemplateRenderer { .init(self) }
}
