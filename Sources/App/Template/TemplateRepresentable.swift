//
//  TemplateRepresentable.swift
//  
//
//  Created by Mico Miloloza on 31.05.2023..
//

import Vapor
import SwiftSgml


public protocol TemplateRepresentable {
    @TagBuilder
    func render(_ req: Request) -> Tag
}
