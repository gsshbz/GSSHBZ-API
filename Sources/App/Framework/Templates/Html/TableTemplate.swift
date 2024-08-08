//
//  TableTemplate.swift
//
//
//  Created by Mico Miloloza on 11.10.2023..
//

import Vapor
import SwiftHtml


public struct TableTemplate: TemplateRepresentable {
    public var context: TableContext
    
    public init(context: TableContext) {
        self.context = context
    }
    
    public func render(_ req: Request) -> Tag {
        Table {
            Thead {
                Tr {
                    context.columns.map { column in
                        Th(column.label)
                            .id(column.key)
                            .class("field")
                    }
                    
                    context.actions.map { action in
                        Th(action.label)
                            .class("action")
                    }
                }
            }
            
            Tbody {
                for row in context.rows {
                    Tr {
                        row.cells.map { CellTemplate($0, rowId: row.id).render(req) }
                        
                        context.actions.map { action in
                            Td {
                                LinkTemplate(action, pathInfix: row.id).render(req)
                            }
                            .class("action")
                        }
                    }
                    .id(row.id)
                }
            }
        }
    }
}
