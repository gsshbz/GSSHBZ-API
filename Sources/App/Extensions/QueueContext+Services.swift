//
//  QueueContext+Services.swift
//
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Fluent
import Queues
//import Mailgun
import SendGrid

extension QueueContext {
    var db: Database {
        application.databases
            .database(logger: self.logger, on: self.eventLoop)!
    }
    
//    func mailgun() -> MailgunProvider {
//        application.mailgun().delegating(to: self.eventLoop)
//    }
//    
//    func mailgun(_ domain: MailgunDomain? = nil) -> MailgunProvider {
//        application.mailgun(domain).delegating(to: self.eventLoop)
//    }
    
    func sendgrid() -> SendGridClient {
        return application.sendgrid.client
    }
    
    var appConfig: AppConfig {
        application.config
    }
}

