
//  UserAccount.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class UserAccount {
    @Attribute(.unique) var userID: String
    var username: String
    var displayName: String
    var email: String
    var role: UserRole
    var isActive: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    var assignedBranchID: String?
    
    init(
        userID: String = UUID().uuidString,
        username: String,
        displayName: String,
        email: String = "",
        role: UserRole = .receptionist,
        isActive: Bool = true
    ) {
        self.userID = userID
        self.username = username
        self.displayName = displayName
        self.email = email
        self.role = role
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    var hasPermission: (Permission) -> Bool {
        { [weak self] permission in
            self?.role.permissions.contains(permission) ?? false
        }
    }
}
