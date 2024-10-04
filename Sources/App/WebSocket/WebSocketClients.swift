//
//  WebsocketClients.swift
//  
//
//  Created by Mico Miloloza on 03.10.2024..
//

import Vapor


open class WebSocketClients {
    var eventLoop: EventLoop
    var storage: [UUID: WebSocketClient]
    
    var active: [WebSocketClient] {
        self.storage.values.filter { !$0.socket.isClosed }
    }

    init(eventLoop: EventLoop, clients: [UUID: WebSocketClient] = [:]) {
        self.eventLoop = eventLoop
        self.storage = clients
    }
    
    func add(_ client: WebSocketClient) {
        self.storage[client.id] = client
    }

    func remove(_ client: WebSocketClient) {
        self.storage[client.id] = nil
    }
    
    func find(_ uuid: UUID) -> WebSocketClient? {
        self.storage[uuid]
    }

    deinit {
        let futures = self.storage.values.map { $0.socket.close() }
        try! self.eventLoop.flatten(futures).wait()
    }
}
