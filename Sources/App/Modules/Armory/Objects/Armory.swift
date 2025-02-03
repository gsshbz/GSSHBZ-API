//
//  Armory.swift
//
//
//  Created by Mico Miloloza on 12.11.2023..
//

import Foundation


public enum Armory: ApiModuleInterface {
    public enum Item: ApiModelInterface {
        public typealias Module = Armory
        
        public static let pathKey: String = "items"
    }
    
    public enum Category: ApiModelInterface {
        public typealias Module = Armory
        
        public static let pathKey: String = "categories"
    }
    
    public enum Lease: ApiModelInterface {
        public typealias Module = Armory
        public static let pathKey: String = "leases"
    }
    
    public enum NewsFeedArticle: ApiModelInterface {
        public typealias Module = Armory
        public static let pathKey: String = "newsFeedArticles"
    }
}
