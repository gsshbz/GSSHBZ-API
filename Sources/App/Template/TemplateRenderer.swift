//
//  TemplateRenderer.swift
//  
//
//  Created by Mico Miloloza on 31.05.2023..
//

import Vapor
import SwiftHtml


public struct TemplateRenderer {
    
    var request: Request
    
    init(_ request: Request) {
        self.request = request
    }
    
    public func renderHtml(_ template: TemplateRepresentable,
                           minify: Bool = false,
                           indent: Int = 4) -> Response {
        let document = Document(.html) {
            template.render(request)
        }
        
        let body = DocumentRenderer(minify: minify, indent: indent).render(document)
        
        return Response(status: .ok,
                        headers: ["Content-Type": "text/html; charset=utf-8"],
                        body: .init(string: body))
    }
}
