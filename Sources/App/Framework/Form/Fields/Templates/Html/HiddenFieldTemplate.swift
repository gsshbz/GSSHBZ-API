//
//  HiddenFieldTemplate.swift
//  
//
//  Created by Mico Miloloza on 30.07.2023..
//
import Vapor
import SwiftHtml


public struct HiddenFieldTemplate: TemplateRepresentable {
    var context: HiddenFieldContext
    
    public init(_ context: HiddenFieldContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        Input()
            .type(.hidden)
            .key(context.key)
            .value(context.value)
    }
}
