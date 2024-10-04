//
//  ArmoryWebSocketSystem.swift
//
//
//  Created by Mico Miloloza on 03.10.2024..
//

import Vapor


class ArmoryWebSocketSystem {
    var clients: WebSocketClients

    init(eventLoop: EventLoop) {
        self.clients = WebSocketClients(eventLoop: eventLoop)
    }
    
    func broadcastArmoryItemUpdated(_ item: Armory.Item.Detail) async throws {
        let message = WebSocketMessage(type: .armoryItemUpdated, data: item)
        try await broadcast(message)
    }
    
    func broadcastNewLeaseCreated(_ lease: Armory.Lease.Detail) async throws {
        let message = WebSocketMessage(type: .newLeaseCreated, data: lease)
        try await broadcast(message)
    }
    
    private func broadcast<T: Codable>(_ message: WebSocketMessage<T>) async throws {
//        let jsonData = try JSONEncoder().encode(message)
//        let buffer = ByteBuffer(data: jsonData)
//        
//        for client in clients.active {
//            client.socket.send(buffer)
//        }
        
        let jsonData = try JSONEncoder().encode(message)
        
        // Convert JSON data to a String
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Failed to encode message to string.")
        }
        
        // Broadcast the string message to all active clients
        for client in clients.active {
            try await client.socket.send(jsonString)
        }
    }
}

extension ArmoryWebSocketSystem {
    static var shared: ArmoryWebSocketSystem!
}
