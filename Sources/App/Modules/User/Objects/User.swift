//
//  User.swift
//
//
//  Created by Mico Miloloza on 07.02.2024..
//

import Foundation


enum User: ApiModuleInterface {
    enum Account: ApiModelInterface {
        typealias Module = User
    }
    
    enum Token: ApiModelInterface {
        typealias Module = User
    }
}
