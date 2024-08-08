//
//  InputFieldTemplate.swift
//  
//
//  Created by Mico Miloloza on 08.07.2023..
//

import Vapor
import SwiftHtml


public struct InputFieldTemplate: TemplateRepresentable {
    public var context: InputFieldContext
    
    public init(_ context: InputFieldContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        LabelTemplate(context.label).render(req)
        
        Input()
            .type(context.type)
            .key(context.key)
            .placeholder(context.placeholder)
            .value(context.value)
            .class("field")
        
        if let error = context.error {
            Span(error)
                .class("error")
        }
    }
}
