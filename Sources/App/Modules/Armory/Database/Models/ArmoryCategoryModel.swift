//
//  ArmoryCategoryModel.swift
//
//
//  Created by Mico Miloloza on 30.10.2023..
//

import Vapor
import Fluent


final class ArmoryCategoryModel: DatabaseModelInterface {
    typealias Module = ArmoryModule
    
    static var identifier: String = "categories"
    
    @ID()
    var id: UUID?
    
    @Field(key: FieldKeys.v1.name)
    var name: String
    
    @Children(for: \.$category)
    var armoryItems: [ArmoryItemModel]
    
    public init() {
        
    }
    
    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
    struct FieldKeys {
        struct v1 {
            static var name: FieldKey { "name" }
        }
    }
}
