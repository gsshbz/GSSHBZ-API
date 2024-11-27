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
    
    func handleIncomingMessage(_ client: WebSocketClient, _ rawMessage: String) async throws {
        guard let messageData = rawMessage.data(using: .utf8) else {
            print("Failed to decode incoming message string.")
            return
        }
        
        do {
            let baseMessage = try JSONDecoder().decode(WebSocketMessage<JSONPayload>.self, from: messageData)
            
            switch baseMessage.type {
            case .ping:
                // Simple ping-pong response
                try await client.socket.send("pong")
                
            default:
                // Handle other custom messages
                print("Custom message received: \(baseMessage.data)")
            }
        } catch {
            print("Error processing message: \(error)")
        }
    }
    
    func broadcastMessage<T: Codable>(type: WebSocketMessageType, _ item: T) async throws {
        let message = WebSocketMessage(type: type, data: item)
        
        try await broadcast(message)
    }
    
    private func broadcast<T: Codable>(_ message: WebSocketMessage<T>) async throws {
        // Pre-encode JSON data once
        let jsonData = try JSONEncoder().encode(message)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Failed to encode message to string.")
        }
        
        // Broadcast pre-encoded JSON string
        await withTaskGroup(of: Void.self) { group in
            for client in clients.active {
                group.addTask {
                    try? await client.socket.send(jsonString)
                }
            }
        }
    }
    
    func connect(_ id: UUID, _ ws: WebSocket) {
        let client = WebSocketClient(id: id, socket: ws)
        self.clients.add(client)
        
//        ws.onText { [weak self] ws, text in
//            guard let self = self else { return }
//            Task {
//                try? await self.handleIncomingMessage(client, text)
//            }
//        }
    }
}

extension ArmoryWebSocketSystem {
    static var shared: ArmoryWebSocketSystem!
}
