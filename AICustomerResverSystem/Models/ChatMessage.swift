
//  ChatMessage.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var messageID: String
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var sessionID: String
    
    init(
        messageID: String = UUID().uuidString,
        content: String,
        isFromUser: Bool,
        sessionID: String = "default"
    ) {
        self.messageID = messageID
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.sessionID = sessionID
    }
}
