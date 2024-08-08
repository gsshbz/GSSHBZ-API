//
//  AsyncValidatorBuilder.swift
//  
//
//  Created by Mico Miloloza on 27.07.2023..
//

import Vapor


@resultBuilder
public enum AsyncValidatorBuilder {
    public static func buildBlock(_ components: AsyncValidator...) -> [AsyncValidator] {
        components
    }
    
}
