//
//  TextareaFieldTemplate.swift
//  
//
//  Created by Mico Miloloza on 30.07.2023..
//

import Vapor
import SwiftHtml


public struct TextareaFieldTemplate: TemplateRepresentable {
    var context: TextareaFieldContext
    
    public init(_ context: TextareaFieldContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        LabelTemplate(context.label).render(req)
        
        Textarea(context.value)
            .placeholder(context.placeholder)
            .name(context.key)
        
        if let error = context.error {
            Span(error)
                .class("error")
        }
    }
}
