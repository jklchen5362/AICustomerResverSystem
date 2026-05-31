
//  AppState.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

@Observable
class AppState {
    var currentUser: UserAccount?
    var selectedBranch: Branch?
    var selectedTab: AppTab = .dashboard
    var isLoading: Bool = false
    var showOnboarding: Bool = false
    var hasLoadedSampleData: Bool = false
    
    // Notification badge count
    var unreadNotificationCount: Int = 0
    
    // Search state
    var globalSearchText: String = ""
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    var currentUserRole: UserRole {
        currentUser?.role ?? .receptionist
    }
    
    func hasPermission(_ permission: Permission) -> Bool {
        currentUserRole.permissions.contains(permission)
    }
}
