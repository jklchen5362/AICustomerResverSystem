
//  AppNotification.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class AppNotification {
    @Attribute(.unique) var notificationID: String
    var type: NotificationType
    var title: String
    var message: String
    var isRead: Bool
    var scheduledDate: Date
    var createdAt: Date
    
    // Relationships
    var customer: Customer?
    
    init(
        notificationID: String = "NTF-" + UUID().uuidString.prefix(6).uppercased(),
        type: NotificationType,
        title: String,
        message: String,
        isRead: Bool = false,
        scheduledDate: Date = Date()
    ) {
        self.notificationID = notificationID
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.scheduledDate = scheduledDate
        self.createdAt = Date()
    }
}
