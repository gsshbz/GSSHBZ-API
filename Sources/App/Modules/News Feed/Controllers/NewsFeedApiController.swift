//
//  NewsFeedApiController.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 03.02.2025..
//


import Vapor
import Fluent


extension Armory.NewsFeedArticle.Create: Content {}
extension Armory.NewsFeedArticle.Detail: Content {}
extension Armory.NewsFeedArticle.List: Content {}


struct NewsFeedApiController: ListController {
    
    typealias ApiModel = Armory.NewsFeedArticle
    typealias DatabaseModel = NewsFeedArticleModel
    typealias CreateObject = Armory.NewsFeedArticle.Create
    typealias UpdateObject = Armory.NewsFeedArticle.Update
    typealias DetailObject = Armory.NewsFeedArticle.Detail
    typealias PatchObject = Armory.NewsFeedArticle.Patch
    typealias ListObject = Armory.NewsFeedArticle.List
    
    var parameterId: String = "newsFeedId"
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        
        baseRoutes.on(.GET, use: listApi)
        baseRoutes.on(.POST, use: createApi)
        baseRoutes.on(.GET, "user-articles", use: getUserNewsArticles)
        
        existingModelRoutes.on(.GET, use: detailApi)
        existingModelRoutes.on(.POST, use: updateApi)
        existingModelRoutes.on(.DELETE, use: deleteApi)
    }
}


extension NewsFeedApiController {
    func createApi(_ req: Request) async throws -> DetailObject {
        let input = try req.content.decode(CreateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let userId = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        // Create news article model
        let newsFeedModel = try NewsFeedArticleModel(userId: userId, title: input.title, text: input.text)
        try await newsFeedModel.save(on: req.db)
        
        let detailOutput = DetailObject(id: try newsFeedModel.requireID(),
                                        title: newsFeedModel.title,
                                        text: newsFeedModel.text,
                                        user: .init(id: try user.requireID(),
                                                    firstName: user.firstName,
                                                    lastName: user.lastName,
                                                    imageKey: user.imageKey,
                                                    email: user.email,
                                                    isAdmin: user.isAdmin),
                                        createdAt: newsFeedModel.createdAt,
                                        updatedAt: newsFeedModel.updatedAt,
                                        deletedAt: newsFeedModel.deletedAt)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .newsArticleCreated, detailOutput)
        
        let latestNews = try await latestNewsApi(req: req)
        let dashboardUpdate = Armory.Dashboard.Detail(latestLeases: nil, recentlyAddedItems: nil, latestNews: latestNews, itemsInArmory: nil, leasedToday: nil)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .dashboard, dashboardUpdate)
        
        return detailOutput
    }
    
    func deleteApi(_ req: Request) async throws -> HTTPStatus {
        let newsFeedModel = try await findBy(identifier(req), on: req.db)
        
        let newsFeedModelId = try newsFeedModel.requireID()
        
        // Delete the NewsFeedModel
        try await newsFeedModel.delete(on: req.db)
        
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .newsArticleDeleted, newsFeedModelId)
        
        return .noContent
    }
    
    func detailApi(_ req: Request) async throws -> DetailObject {
        guard let newsFeedModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.newsArticleNotFound
        }
        
        return .init(id: try newsFeedModel.requireID(),
                     title: newsFeedModel.title,
                     text: newsFeedModel.text,
                     user: .init(id: try newsFeedModel.user.requireID(),
                                 firstName: newsFeedModel.user.firstName,
                                 lastName: newsFeedModel.user.lastName,
                                 imageKey: newsFeedModel.user.imageKey,
                                 email: newsFeedModel.user.email,
                                 isAdmin: newsFeedModel.user.isAdmin),
                     createdAt: newsFeedModel.createdAt,
                     updatedAt: newsFeedModel.updatedAt,
                     deletedAt: newsFeedModel.deletedAt)
    }
    
    func updateApi(_ req: Request) async throws -> DetailObject {
        let updateObject = try req.content.decode(UpdateObject.self)
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db),
              let userId = try? user.requireID() else {
            throw AuthenticationError.userNotFound
        }
        
        // Fetch the existing lease, including user and items
        guard let newsFeedArticleModel = try await DatabaseModel.query(on: req.db)
            .with(\.$user)
            .filter(\.$id == identifier(req))
            .first() else {
            throw ArmoryErrors.newsArticleNotFound
        }
        
        if userId != newsFeedArticleModel.$user.id {
            newsFeedArticleModel.$user.id = userId
        }
        newsFeedArticleModel.title = updateObject.title
        newsFeedArticleModel.text = updateObject.text
        
        try await newsFeedArticleModel.update(on: req.db)
        
        let updatedNewsFeedArticle = DetailObject(id: try newsFeedArticleModel.requireID(),
                                                  title: newsFeedArticleModel.title,
                                                  text: newsFeedArticleModel.text,
                                                  user: .init(id: userId,
                                                              firstName: user.firstName,
                                                              lastName: user.lastName,
                                                              imageKey: user.imageKey,
                                                              email: user.email,
                                                              isAdmin: user.isAdmin),
                                                  createdAt: newsFeedArticleModel.createdAt,
                                                  updatedAt: newsFeedArticleModel.updatedAt,
                                                  deletedAt: newsFeedArticleModel.deletedAt)
       
        try await ArmoryWebSocketSystem.shared.broadcastMessage(type: .newsArticleUpdated, updatedNewsFeedArticle)
        
        return updatedNewsFeedArticle
    }
    
    func listApi(_ req: Request) async throws -> ListObject {
        let models = try await paginatedList(req,
                                    queryBuilders: { $0.with(\.$user) }
        )
        
        let newsArticleModels: [DetailObject] = try models.items.map { .init(id: try $0.requireID(),
                                                             title: $0.title,
                                                             text: $0.text,
                                                             user: .init(id: try $0.user.requireID(),
                                                                         firstName: $0.user.firstName,
                                                                         lastName: $0.user.lastName,
                                                                         imageKey: $0.user.imageKey,
                                                                         email: $0.user.email,
                                                                         isAdmin: $0.user.isAdmin),
                                                             createdAt: $0.createdAt,
                                                             updatedAt: $0.updatedAt,
                                                             deletedAt: $0.deletedAt) }
       
        return .init(news: newsArticleModels, metadata: .init(page: models.metadata.page,
                                                              per: models.metadata.per,
                                                              total: models.metadata.total))
    }
    
    func getUserNewsArticles(_ req: Request) async throws -> ListObject {
        let jwtUser = try req.auth.require(JWTUser.self)
        
        guard let user = try await UserAccountModel.find(jwtUser.userId, on: req.db) else {
            throw AuthenticationError.userNotFound
        }
        
        let userId = try user.requireID()
        
        let models = try await paginatedList(req,
                                    queryBuilders: { $0.with(\.$user) },
                                    { $0.filter(\.$user.$id == userId) }
        )
        
        let newsArticleModels: [DetailObject] = try models.items.map { .init(id: try $0.requireID(),
                                                             title: $0.title,
                                                             text: $0.text,
                                                             user: .init(id: try $0.user.requireID(),
                                                                         firstName: $0.user.firstName,
                                                                         lastName: $0.user.lastName,
                                                                         imageKey: $0.user.imageKey,
                                                                         email: $0.user.email,
                                                                         isAdmin: $0.user.isAdmin),
                                                             createdAt: $0.createdAt,
                                                             updatedAt: $0.updatedAt,
                                                             deletedAt: $0.deletedAt) }
       
        return .init(news: newsArticleModels, metadata: .init(page: models.metadata.page,
                                                              per: models.metadata.per,
                                                              total: models.metadata.total))
    }
    
    /// Fetches the 5 most recent news articles.
    func latestNewsApi(req: Request) async throws -> [Armory.NewsFeedArticle.Detail] {
        let newsArticles = try await NewsFeedArticleModel.query(on: req.db)
            .with(\.$user)
            .sort(\.$createdAt, .descending)
            .limit(5)
            .all()
        
        let newsArticleModels: [DetailObject] = try newsArticles.map { article in
                .init(id: try article.requireID(),
                      title: article.title,
                      text: article.text,
                      user: .init(id: try article.user.requireID(),
                                  firstName: article.user.firstName,
                                  lastName: article.user.lastName,
                                  imageKey: article.user.imageKey,
                                  email: article.user.email,
                                  isAdmin: article.user.isAdmin),
                      createdAt: article.createdAt,
                      updatedAt: article.updatedAt,
                      deletedAt: article.deletedAt)
        }
        
        return newsArticleModels
    }
}

