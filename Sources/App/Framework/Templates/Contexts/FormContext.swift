//
//  FormContext.swift
//  
//
//  Created by Mico Miloloza on 08.07.2023..
//

import Foundation

public struct FormContext {
    public var action: FormAction
    public var fields: [TemplateRepresentable]
    public var error: String?
    public var submit: String?
}
