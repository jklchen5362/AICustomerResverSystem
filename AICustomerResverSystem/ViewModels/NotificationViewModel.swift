//  NotificationViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class NotificationViewModel {
    var selectedTypeFilter: NotificationType? = nil
    
    init() {}
    
    func filteredNotifications(_ notifications: [AppNotification]) -> [AppNotification] {
        var results = notifications
        
        if let filter = selectedTypeFilter {
            results = results.filter { $0.type == filter }
        }
        
        // Sort: Scheduled date descending
        results.sort(by: { $0.scheduledDate > $1.scheduledDate })
        
        return results
    }
    
    @MainActor
    func markAsRead(_ notification: AppNotification, context: ModelContext) {
        notification.isRead = true
        try? context.save()
    }
    
    @MainActor
    func markAllAsRead(notifications: [AppNotification], context: ModelContext) {
        for notif in notifications {
            notif.isRead = true
        }
        try? context.save()
    }
    
    @MainActor
    func deleteNotification(_ notification: AppNotification, context: ModelContext) {
        context.delete(notification)
        try? context.save()
    }
    
    func unreadCount(notifications: [AppNotification]) -> Int {
        notifications.filter { !$0.isRead }.count
    }
}
