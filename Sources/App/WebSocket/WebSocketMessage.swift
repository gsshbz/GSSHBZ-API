//
//  WebSocketMessage.swift
//
//
//  Created by Mico Miloloza on 03.10.2024..
//

import Vapor


enum WebSocketMessageType: String, Codable {
    // Armory item
    case armoryItemCreated
    case armoryItemUpdated
    case armoryItemDeleted
    
    // Category
    case categoryCreated
    case categoryUpdated
    case categoryDeleted
    
    // Lease
    case leaseCreated
    case leaseUpdated
    case leaseDeleted
    
    // Dashboard
    case dashboardUpdate
    
    case ping
}

struct WebSocketMessage<T: Codable>: Codable {
    let type: WebSocketMessageType
    let data: T
}

extension Data {
    func decodeWebSocketMessage<T: Codable>(_ type: T.Type) -> WebSocketMessage<T>? {
        try? JSONDecoder().decode(WebSocketMessage<T>.self, from: self)
    }
}

extension ByteBuffer {
    func decodeWebSocketMessage<T: Codable>(_ type: T.Type) -> WebSocketMessage<T>? {
        try? JSONDecoder().decode(WebSocketMessage<T>.self, from: self)
    }
}

extension String {
    func decodeWebSocketMessage<T: Codable>(_ type: T.Type) -> WebSocketMessage<T>? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(WebSocketMessage<T>.self, from: data)
    }
}
