//
//  LabelTemplate.swift
//  
//
//  Created by Mico Miloloza on 08.07.2023..
//

import Vapor
import SwiftHtml


public struct LabelTemplate: TemplateRepresentable {
    public var context: LabelContext
    
    public init(_ context: LabelContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        Label {
            Text(context.title ?? context.key.capitalized)
            
            if let more = context.more {
                Span(more)
                    .class("more")
            }
            
            if context.required {
                Span("*")
                    .class("required")
            }
        }.for(context.key)
    }
}
