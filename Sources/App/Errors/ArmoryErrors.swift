//
//  ArmoryErrors.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 23.10.2024..
//

import Vapor



enum ArmoryErrors: AppError {
    case categoryNotFound
    case armoryItemNotFound
    case duplicateItemName(String)
}

extension ArmoryErrors: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .categoryNotFound:
            return .notFound
            
        case .armoryItemNotFound:
            return .notFound
            
        case .duplicateItemName(let name):
            return .conflict
        }
    }
    
    var reason: String {
        switch self {
        case .categoryNotFound:
            return "Category couldn't be found"
            
        case .armoryItemNotFound:
            return "Armory Item couldn't be found"
            
        case .duplicateItemName(let name):
            return "An armory item with the name '\(name)' already exists. Please choose a different name."
        }
    }
    
    var identifier: String {
        switch self {
        case .categoryNotFound:
            return "category_not_found"
            
        case .armoryItemNotFound:
            return "armory_item_not_found"
            
        case .duplicateItemName(let name):
            return "duplicate_item_name"
        }
    }
    
    
}
