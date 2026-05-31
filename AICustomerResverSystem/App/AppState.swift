
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
    var googleSpreadsheetID: String {
        get { UserDefaults.standard.string(forKey: "google_spreadsheet_id") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "google_spreadsheet_id") }
    }
    
    var googleSpreadsheetName: String {
        get { UserDefaults.standard.string(forKey: "google_spreadsheet_name") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "google_spreadsheet_name") }
    }
    
    var googleLastSyncTime: Double {
        get { UserDefaults.standard.double(forKey: "google_last_sync_time") }
        set { UserDefaults.standard.set(newValue, forKey: "google_last_sync_time") }
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
