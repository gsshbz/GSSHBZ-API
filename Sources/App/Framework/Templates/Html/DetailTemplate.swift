//
//  DetailTemplate.swift
//
//
//  Created by Mico Miloloza on 16.10.2023..
//

import Vapor
import SwiftHtml


public struct DetailTemplate: TemplateRepresentable {
    var context: DetailContext
    
    public init(_ context: DetailContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        Dt(context.label)
        
        switch context.type {
        case .text:
            if context.value.isEmpty {
                Dd("&nbsp;")
            } else {
                Dd(
                    context.value.replacingOccurrences(of: "\n", with: "<br>")
                )
            }
        case .image:
            Dd {
                Img(
                    src: context.value,
                    alt: context.label
                )
            }
        }
    }
}
