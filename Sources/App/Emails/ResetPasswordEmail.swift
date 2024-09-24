//
//  ResetPasswordEmail.swift
//  
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor


struct ResetPasswordEmail: Email {
    var templateId: String = Environment.get("SENDGRID_TEMPLATE_ID") ?? ""
    var templateName: String = "Reset Password GSSHBZ"
    var templateData: [String : String] {
        ["resetUrl": resetURL]
    }
    var subject: String {
        "Reset your password"
    }
    
    let resetURL: String
    
    init(resetURL: String) {
        self.resetURL = resetURL
    }
}


