//
//  CellTemplate.swift
//
//
//  Created by Mico Miloloza on 10.10.2023..
//

import Vapor
import SwiftHtml


public struct CellTemplate: TemplateRepresentable {
    public var context: CellContext
    public var rowId: String
    
    public init(_ context: CellContext, rowId: String) {
        self.context = context
        self.rowId = rowId
    }
    
    public func render(_ req: Request) -> Tag {
        Td {
            switch context.type {
            case .text:
                if let link = context.link {
                    LinkTemplate(link, pathInfix: rowId).render(req)
                } else {
                    Text(context.value)
                }
            case .image:
                if let link = context.link {
                    LinkTemplate(link, pathInfix: rowId) { label in
                        Img(src: context.value, alt: label)
                    }
                    .render(req)
                } else {
                    Img(src: context.value, alt: context.value)
                }
            }
        }
        .class("field")
    }
}
