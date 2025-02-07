//
//  NewsFeedArticleModel.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Vapor
import Fluent


final class NewsFeedArticleModel: DatabaseModelInterface {
    typealias Module = LeaseModule
    
    @ID
    var id: UUID?
    
    @Parent(key: FieldKeys.v1.userId)
    var user: UserAccountModel
    
    @Field(key: FieldKeys.v1.title)
    var title: String
    
    @Field(key: FieldKeys.v1.text)
    var text: String
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, userId: UUID, title: String, text: String, createdAt: Date? = nil, updatedAt: Date? = nil, deletedAt: Date? = nil) throws {
        self.id = id
        self.$user.id = userId
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}


extension NewsFeedArticleModel {
    struct FieldKeys {
        struct v1 {
            static var id: FieldKey { "id" }
            static var userId: FieldKey { "user_id" }
            static var title: FieldKey { "title" }
            static var text: FieldKey { "text" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
}

