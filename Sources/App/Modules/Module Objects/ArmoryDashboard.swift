//
//  ArmoryDashboard.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 12.02.2025..
//


public extension Armory.Dashboard  {
    struct Detail: Codable {
        let latestLeases: [Armory.Lease.Detail]?
        let recentlyAddedItems: [Armory.Item.List]?
        let latestNews: [Armory.NewsFeedArticle.Detail]?
        let itemsInArmory: Int?
        let leasedToday: Int?
    }
}
