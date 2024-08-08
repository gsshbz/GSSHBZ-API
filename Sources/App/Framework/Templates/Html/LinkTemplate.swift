//
//  LinkTemplate.swift
//
//
//  Created by Mico Miloloza on 10.10.2023..
//

import Vapor
import SwiftHtml


struct LinkTemplate: TemplateRepresentable {
    var context: LinkContext
    var body: Tag
    var pathInfix: String?
    
    public init(_ context: LinkContext, pathInfix: String? = nil, _ builder: ((String) -> Tag)? = nil) {
        self.context = context
        self.pathInfix = pathInfix
        self.body = builder?(context.label) ?? Text(context.label)
    }
    
    func render(_ req: Request) -> Tag {
        A { body }
            .href(context.url(req, pathInfix?.pathComponents ?? []))
            .target(.blank, context.isBlank)
    }
}
