//
//  AbstractForm.swift
//  
//
//  Created by Mico Miloloza on 08.07.2023..
//

import Vapor
import SwiftHtml


/**
 FormFieldComponent events suggested order of execution:
 - When displaying the form:
     - load
     - read
     - render
 - When handling a submission event:
     - load
     - process
     - validate
     - render if invalid
     - write
     - save
 */
open class AbstractForm: FormComponent {
    open var action: FormAction
    open var fields: [FormComponent]
    open var error: String?
    open var submit: String?
    
    public init(action: FormAction = .init(), fields: [FormComponent] = [], error: String? = nil, submit: String? = nil) {
        self.action = action
        self.fields = fields
        self.error = error
        self.submit = submit
    }
    
    public func load(req: Request) async throws {
        for field in fields {
            try await field.load(req: req)
        }
    }
    
    public func process(req: Request) async throws {
        for field in fields {
            try await field.process(req: req)
        }
    }
    
    public func validate(req: Request) async throws -> Bool {
        var result: [Bool] = []
        
        for field in fields {
            result.append(try await field.validate(req: req))
        }
        
        return result.filter { $0 == false }.isEmpty
    }
    
    public func write(req: Request) async throws {
        for field in fields {
            try await field.write(req: req)
        }
    }
    
    public func save(req: Request) async throws {
        for field in fields {
            try await field.save(req: req)
        }
    }
    
    public func read(req: Request) async throws {
        for field in fields {
            try await field.read(req: req)
        }
    }
    
    public func render(req: Request) -> TemplateRepresentable {
        FormTemplate(getContext(req))
    }
    
    func getContext(_ req: Request) -> FormContext {
        .init(action: action,
              fields: fields.map { $0.render(req: req) },
              error: error,
              submit: submit
        )
    }
}
