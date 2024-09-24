//
//  RequestService.swift
//
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor


protocol RequestService {
    func `for`(_ req: Request) -> Self
}
