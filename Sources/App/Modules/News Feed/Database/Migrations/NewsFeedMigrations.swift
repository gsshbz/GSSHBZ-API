//
//  NewsFeedMigrations.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//

import Fluent
import Vapor


enum NewsFeedMigrations {
    struct v1: AsyncMigration {
        func prepare(on database: Database) async throws {
            // MARK: - LeaseModel
            try await database.schema(NewsFeedArticleModel.schema)
                .id()
                .field(NewsFeedArticleModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(NewsFeedArticleModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
                .field(NewsFeedArticleModel.FieldKeys.v1.title, .string)
                .field(NewsFeedArticleModel.FieldKeys.v1.text, .string)
                .field(NewsFeedArticleModel.FieldKeys.v1.createdAt, .datetime)
                .field(NewsFeedArticleModel.FieldKeys.v1.updatedAt, .datetime)
                .field(NewsFeedArticleModel.FieldKeys.v1.deletedAt, .datetime)
                .create()
        }
        
        
        
        func revert(on database: Database) async throws {
            try await database.schema(NewsFeedArticleModel.schema).delete()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on database: any Database) async throws {
            let user = try await UserAccountModel.query(on: database)
                .filter(\.$email == "root@localhost.localhost")
                .first() // Fetch an existing user
            
            guard let user = user else {
                throw Abort(.internalServerError, reason: "No user found for seeding leases.")
            }

            let newsFeed1 = try NewsFeedArticleModel(userId: try user.requireID(), title: "Obavijest o sastanku", text: "Sastanak u stanici će biti 15.02.2025 u 19h.")
            let newsFeed2 = try NewsFeedArticleModel(userId: try user.requireID(), title: "Vježba spašavanja na Kamešnici", text: "Vježba će se održati od 10.4 do 12.04. Na sastanku ćemo dogovarati detalje i napraviti spisak ljudi koji će sudjelovati.")
            let newsFeed3 = try NewsFeedArticleModel(userId: try user.requireID(), title: "Obavijest o nabavci nove opreme", text: "Nabavili smo novi paket karabinera, 10 novih jakni, 1 mariner i 7 užadi od 100m.")
            
            try await newsFeed1.create(on: database)
            try await newsFeed2.create(on: database)
            try await newsFeed3.create(on: database)
        }
        
        func revert(on database: any Database) async throws {
            try await NewsFeedArticleModel.query(on: database).delete()
        }
    }
}
