
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
    
    // Stored strings for instant UI updates of Dashboard welcome card
    var consultantName: String = "諮詢顧問"
    var branchName: String = "台北總店"
    
    // Google Sheets Sync Configuration
    var googleSpreadsheetID: String = "" {
        didSet { UserDefaults.standard.set(googleSpreadsheetID, forKey: "google_spreadsheet_id") }
    }
    
    var googleSpreadsheetName: String = "" {
        didSet { UserDefaults.standard.set(googleSpreadsheetName, forKey: "google_spreadsheet_name") }
    }
    
    var googleLastSyncTime: Double = 0 {
        didSet { UserDefaults.standard.set(googleLastSyncTime, forKey: "google_last_sync_time") }
    }
    
    init() {
        self.googleSpreadsheetID = UserDefaults.standard.string(forKey: "google_spreadsheet_id") ?? ""
        self.googleSpreadsheetName = UserDefaults.standard.string(forKey: "google_spreadsheet_name") ?? ""
        self.googleLastSyncTime = UserDefaults.standard.double(forKey: "google_last_sync_time")
    }
    
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
