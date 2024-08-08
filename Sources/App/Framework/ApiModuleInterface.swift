//
//  ApiModuleInterface.swift
//
//
//  Created by Mico Miloloza on 28.12.2023..
//

import Foundation


public protocol ApiModuleInterface {
    static var pathKey: String { get }
}

public extension ApiModuleInterface {
    static var pathKey: String {
        String(describing: self).lowercased()
    }
}
