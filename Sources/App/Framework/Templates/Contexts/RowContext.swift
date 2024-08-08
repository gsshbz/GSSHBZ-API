//
//  RowContext.swift
//
//
//  Created by Mico Miloloza on 11.10.2023..
//

import Foundation


public struct RowContext {
    public let id: String
    public let cells: [CellContext]
    
    public init(id: String, cells: [CellContext]) {
        self.id = id
        self.cells = cells
    }
}
