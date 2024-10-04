//
//  WebSocketClient.swift
//  
//
//  Created by Mico Miloloza on 03.10.2024..
//

import Vapor


open class WebSocketClient {
    open var id: UUID
    open var socket: WebSocket

    public init(id: UUID, socket: WebSocket) {
        self.id = id
        self.socket = socket
    }
}
