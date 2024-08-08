//
//  ByteBuffer+Data.swift
//  
//
//  Created by Mico Miloloza on 02.08.2023..
//

import Vapor


public extension ByteBuffer {
    var data: Data? {
        getData(at: 0, length: readableBytes)
    }
}
