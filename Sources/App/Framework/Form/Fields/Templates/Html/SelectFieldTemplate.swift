//
//  SelectFieldTemplate.swift
//  
//
//  Created by Mico Miloloza on 30.07.2023..
//

import Vapor
import SwiftHtml


public final class SelectFieldTemplate: TemplateRepresentable {
    var context: SelectFieldContext
    
    public init(_ context: SelectFieldContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        LabelTemplate(context.label).render(req)
        
        Select {
            for item in context.options {
                Option(item.label)
                    .value(item.key)
                    .selected(context.value == item.key)
            }
        }
        .name(context.key)
        
        if let error = context.error {
            Span(error)
                .class("error")
        }
    }
}
