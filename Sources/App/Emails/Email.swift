//
//  Email.swift
//  
//
//  Created by Mico Miloloza on 03.09.2024..
//


protocol Email: Codable {
    var templateId: String { get }
    var templateName: String { get }
    var templateData: [String: String] { get }
    var subject: String { get }
}

struct AnyEmail: Email {
    var templateId: String
    var templateName: String
    var templateData: [String : String]
    var subject: String
    
    init<E>(_ email: E) where E: Email {
        self.templateId = email.templateId
        self.templateData = email.templateData
        self.templateName = email.templateName
        self.subject = email.subject
    }
}

