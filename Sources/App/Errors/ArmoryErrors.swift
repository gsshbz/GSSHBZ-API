//
//  ArmoryErrors.swift
//  GSSHBZ
//
//  Created by Mico Miloloza on 23.10.2024..
//

import Vapor



enum ArmoryErrors: AppError {
    // Categories
    case categoryNotFound
    case duplicateCategoryName(String)
    case categoryDeleteFailed(categoryName: String)
    case categoryUpdateFailed(categoryName: String)
    
    // Armory items
    case armoryItemNotFound
    case duplicateArmoryItemName(itemName: String)
    case insufficientArmoryItemStock(itemName: String, requested: Int, available: Int)
    case armoryItemQuantityNotSufficient
    case armoryItemDeleteFailed(itemName: String)
    case armoryItemUpdateFailed(itemName: String)
    case notAllItemsReturned
    
    // Leases
    case leaseNotFound
    case leaseAlreadyClosed
    case leaseAlreadyOpened
    case leaseItemNotAvailable(itemName: String)
    case leaseUpdateFailed(leaseId: UUID)
    case leaseDeleteFailed(leaseId: UUID)
    
    // NewsFeed
    case newsArticleNotFound
    case newsArticleDeleteFailed(newsTitle: String)
    
    case unknownError
    case unauthorizedAccess
}

extension ArmoryErrors {
    var status: HTTPResponseStatus {
        switch self {
        case .categoryNotFound, .leaseNotFound, .armoryItemNotFound, .leaseItemNotAvailable, .newsArticleNotFound:
            return .notFound
            
        case .duplicateArmoryItemName, .duplicateCategoryName, .insufficientArmoryItemStock, .leaseAlreadyClosed, .leaseAlreadyOpened, .armoryItemQuantityNotSufficient, .notAllItemsReturned:
            return .conflict
            
        case .unauthorizedAccess:
            return .forbidden
            
        case .categoryDeleteFailed, .categoryUpdateFailed, .leaseDeleteFailed, .leaseUpdateFailed, .armoryItemUpdateFailed, .armoryItemDeleteFailed, .newsArticleDeleteFailed:
            return .internalServerError
            
        case .unknownError:
            return .internalServerError
        }
    }
    
    var reason: String {
        switch self {
        case .categoryNotFound:
            return "Category couldn't be found"
            
        case .armoryItemNotFound:
            return "Armory Item couldn't be found"
            
        case .duplicateArmoryItemName(let name):
            return "An armory item with the name '\(name)' already exists. Please choose a different name."
            
        case .duplicateCategoryName(let categoryName):
            return "Category with the name '\(categoryName)' already exists. Please choose a different name."
            
        case .categoryDeleteFailed(categoryName: let categoryName):
            return "Category with name '\(categoryName)' couldn't be deleted."
            
        case .categoryUpdateFailed(categoryName: let categoryName):
            return "Category with name '\(categoryName)' couldn't be updated."
            
        case .insufficientArmoryItemStock(itemName: let itemName, requested: let requested, available: let available):
            return "Not enough stock for '\(itemName)'. Requested: \(requested), Available: \(available)."
            
        case .armoryItemQuantityNotSufficient:
            return "Armory item quantity needs to be more than 0"
            
        case .armoryItemDeleteFailed(itemName: let itemName):
            return "Armory item with name '\(itemName)' couldn't be deleted."
            
        case .armoryItemUpdateFailed(itemName: let itemName):
            return "Armory item with name '\(itemName)' couldn't be updated."
            
        case .notAllItemsReturned:
            return "Please, return all items first."
            
        case .leaseNotFound:
            return "Lease couldn't be found"
            
        case .leaseAlreadyClosed:
            return "This lease has already been closed and cannot be modified."
            
        case .leaseAlreadyOpened:
            return "This lease is already opened."
            
        case .leaseItemNotAvailable(itemName: let itemName):
            return "Item '\(itemName)' is not available for lease."
            
        case .leaseUpdateFailed(leaseId: let leaseId):
            return "Failed to update lease with ID \(leaseId). Please try again later."
            
        case .leaseDeleteFailed(leaseId: let leaseId):
            return "Failed to delete lease with ID \(leaseId). Please try again later."
            
        case .unknownError:
            return "Unknown error"
        case .unauthorizedAccess:
            return "You do not have permission to access."
        case .newsArticleNotFound:
            return "News couldn't be found"
        case .newsArticleDeleteFailed(newsTitle: let newsTitle):
            return "Failed to delete news feed with title '\(newsTitle)'. Please try again later."
        }
    }
    
    var identifier: String {
        switch self {
        case .categoryNotFound:
            return "category_not_found"
            
        case .armoryItemNotFound:
            return "armory_item_not_found"
            
        case .duplicateArmoryItemName:
            return "duplicate_item_name"
            
        case .duplicateCategoryName:
            return "duplicate_category_name"
            
        case .categoryDeleteFailed:
            return "category_delete_failed"
            
        case .categoryUpdateFailed:
            return "category_update_failed"
            
        case .insufficientArmoryItemStock:
            return "insufficient_armory_item_stock"
            
        case .armoryItemDeleteFailed:
            return "armory_item_delete_failed"
            
        case .armoryItemUpdateFailed:
            return "armory_item_update_failed"
            
        case .notAllItemsReturned:
            return "not_all_items_returned"
            
        case .leaseNotFound:
            return "lease_not_found"
            
        case .leaseAlreadyClosed:
            return "lease_already_closed"
            
        case .leaseAlreadyOpened:
            return "lease_already_opened"
            
        case .leaseItemNotAvailable:
            return "lease_item_not_available"
            
        case .leaseUpdateFailed:
            return "lease_update_failed"
            
        case .leaseDeleteFailed:
            return "lease_delete_failed"
            
        case .unknownError:
            return "unknown_error"
            
        case .unauthorizedAccess:
            return "unauthorized_access"
            
        case .newsArticleNotFound:
            return "news_article_not_found"
            
        case .newsArticleDeleteFailed:
            return "news_article_delete_failed"
            
        case .armoryItemQuantityNotSufficient:
            return "armory_item_quantity_not_sufficient"
        }
    }
    
    
}
