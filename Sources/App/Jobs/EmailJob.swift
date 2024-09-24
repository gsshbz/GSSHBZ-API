//
//  EmailJob.swift
//
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor
import Queues
import SendGrid


struct EmailPayload: Codable {
    let email: AnyEmail
    let recipient: String
    
    init<E: Email>(_ email: E, to recipient: String) {
        self.email = AnyEmail(email)
        self.recipient = recipient
    }
}

struct EmailJob: Job {
    typealias Payload = EmailPayload
    
    func dequeue(_ context: QueueContext, _ payload: EmailPayload) -> EventLoopFuture<Void> {
        let recipient = EmailAddress(email: payload.recipient)
        
        let fromEmail = EmailAddress(
            email: context.appConfig.noReplyEmail,
            name: "GSSHBŽ")
        
        let personalization = Personalization(to: [recipient], dynamicTemplateData: payload.email.templateData)
        
        let email = SendGridEmail(
            personalizations: [personalization],
            from: fromEmail,
            templateId: payload.email.templateId
        )
        
        
        do {
            let sent = try context
                .sendgrid()
                .send(email: email, on: context.queue.eventLoop)
            
            return sent
        } catch {
            context.application.logger.error("\(error)")
        }
        
        return context.eventLoop.future()
//        return context.mailgun().send(mailgunMessage).transform(to: ())
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: EmailPayload) -> EventLoopFuture<Void> {
        context.application.logger.error("\(error)")
        return context.eventLoop.future()
    }
}
