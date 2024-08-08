//
//  AbstractFormField.swift
//  
//
//  Created by Mico Miloloza on 08.07.2023..
//

import Vapor

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
open class AbstractFormField<Input: Decodable, Output: TemplateRepresentable>: FormComponent {
    var key: String
    var input: Input
    var output: Output
    var error: String?
    
    public typealias FormFieldBlock = (Request, AbstractFormField<Input, Output>) async throws -> Void
    public typealias FormFieldValidatorsBlock = (Request, AbstractFormField<Input, Output>) -> [AsyncValidator]
    
    private var readBlock: FormFieldBlock?
    private var writeBlock: FormFieldBlock?
    private var loadBlock: FormFieldBlock?
    private var saveBlock: FormFieldBlock?
    private var validatorsBlock: FormFieldValidatorsBlock?
    
    public init(key: String, input: Input, output: Output, error: String? = nil) {
        self.key = key
        self.input = input
        self.output = output
        self.error = error
    }
    
    open func config(_ block: (AbstractFormField<Input, Output>) -> Void) -> Self {
        block(self)
        
        return self
    }
    
    // MARK: - Block setters
    open func read(_ block: @escaping FormFieldBlock) -> Self {
        readBlock = block
        return self
    }
    
    open func write(_ block: @escaping FormFieldBlock) -> Self {
        writeBlock = block
        return self
    }
    
    open func load(_ block: @escaping FormFieldBlock) -> Self {
        loadBlock = block
        return self
    }
    
    open func save(_ block: @escaping FormFieldBlock) -> Self {
        saveBlock = block
        return self
    }
    
    open func validators(@AsyncValidatorBuilder _ block: @escaping FormFieldValidatorsBlock) -> Self {
        validatorsBlock = block
        return self
    }
    
    open func process(req: Request) async throws {
        if let value = try? req.content.get(Input.self, at: key) {
            input = value
        }
    }
    
    // MARK: - FormComponent protocol
    open func validate(req: Request) async throws -> Bool {
        guard let validators = validatorsBlock else { return true }
        
        return await RequestValidator(validators(req, self)).isValid(req)
    }
    
    open func read(req: Request) async throws {
        try await readBlock?(req, self)
    }
    
    open func write(req: Request) async throws {
        try await writeBlock?(req, self)
    }
    
    open func load(req: Request) async throws {
        try await loadBlock?(req, self)
    }
    
    open func save(req: Request) async throws {
        try await saveBlock?(req, self)
    }
    
    open func render(req: Request) -> TemplateRepresentable {
        return output
    }
}
