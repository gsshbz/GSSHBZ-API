//
//  FormComponentBuilder.swift
//  
//
//  Created by Mico Miloloza on 10.07.2023..
//

import Foundation


@resultBuilder
public enum FormComponentBuilder {
    public static func buildBlock(_ components: FormComponent...) -> [FormComponent] {
        return components
    }
}
