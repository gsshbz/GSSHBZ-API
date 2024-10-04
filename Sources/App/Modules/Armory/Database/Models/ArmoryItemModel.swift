//
//  ArmoryItemModel.swift
//
//
//  Created by Mico Miloloza on 30.10.2023..
//

import Vapor
import Fluent


final class ArmoryItemModel: DatabaseModelInterface {
    typealias Module = ArmoryModule
    
    static var identifier: String = "armory_items"
    
    @ID()
    var id: UUID?
    
//    @Siblings(through: LeaseItemModel.self, from: \.$armoryItem, to: \.$lease)
//    var leases: [LeaseModel]
    
    @Field(key: FieldKeys.v1.name)
    var name: String
    
    @Field(key: FieldKeys.v1.imageKey)
    var imageKey: String
    
    @Field(key: FieldKeys.v1.aboutInfo)
    var aboutInfo: String
    
    @Field(key: FieldKeys.v1.inStock)
    var inStock: Int
    
    @OptionalParent(key: FieldKeys.v1.categoryId)
    var category: ArmoryCategoryModel?
    
    public init() { }
    
    public init(id: UUID? = nil, name: String, imageKey: String, aboutInfo: String, categoryId: UUID, inStock: Int = 0) {
        self.id = id
        self.name = name
        self.imageKey = imageKey
        self.aboutInfo = aboutInfo
        $category.id = categoryId
        self.inStock = inStock
    }
    
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var name: FieldKey { "name" }
            static var imageKey: FieldKey { "image_key" }
            static var categoryId: FieldKey { "category_id" }
            static var inStock: FieldKey { "in_stock" }
            static var aboutInfo: FieldKey { "about_info" }
        }
    }
}


struct ArmoryItemModelUpdateMiddleware: AsyncModelMiddleware {
    func update(model: ArmoryItemModel, on db: Database, next: AnyAsyncModelResponder) async throws {
        Task {
            try await ArmoryWebSocketSystem.shared.broadcastArmoryItemUpdated(.init(id: try model.requireID(), name: model.name, imageKey: model.imageKey, aboutInfo: model.aboutInfo, inStock: model.inStock, category: model.category != nil ? .init(id: try model.category!.requireID(), name: model.category!.name) : nil))
        }
        
        try await next.update(model, on: db)
    }
}
