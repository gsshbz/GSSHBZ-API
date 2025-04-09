//
//  PasswordResetter.swift
//
//
//  Created by Mico Miloloza on 03.09.2024..
//

import Vapor
import Queues


//struct PasswordResetter {
//    let queue: Queue
//    let repository: PasswordTokenRepository
//    let eventLoop: EventLoop
//    let config: AppConfig
//    let generator: RandomGenerator
//    
//    /// Sends a email to the user with a reset-password URL
//    func reset(for user: UserAccountModel) async throws {
//        let token = generator.generate(bits: 256)
//        let resetPasswordToken = try PasswordTokenModel(userId: user.requireID(), token: SHA256.hash(token))
//        let url = resetURL(for: token)
//        let email = ResetPasswordEmail(resetURL: url)
//        
//        try await repository.create(resetPasswordToken)
//        
//        try await self.queue.dispatch(EmailJob.self, .init(email, to: user.email))
//    }
//    
//    private func resetURL(for token: String) -> String {
//        "\(config.frontendUrl)/api/reset-password?token=\(token)"
//    }
//}
//
//extension Request {
//    var passwordResetter: PasswordResetter {
//        .init(queue: self.queue, repository: self.passwordTokens, eventLoop: self.eventLoop, config: self.application.config, generator: self.application.random)
//    }
//}
