
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
        didSet { 
            UserDefaults.standard.set(googleSpreadsheetID, forKey: "google_spreadsheet_id") 
            setupAutoSyncTimer()
        }
    }
    
    var googleSpreadsheetName: String = "" {
        didSet { UserDefaults.standard.set(googleSpreadsheetName, forKey: "google_spreadsheet_name") }
    }
    
    var googleLastSyncTime: Double = 0 {
        didSet { UserDefaults.standard.set(googleLastSyncTime, forKey: "google_last_sync_time") }
    }
    
    // Auto Sync Scheduler State
    var googleAutoSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(googleAutoSyncEnabled, forKey: "google_auto_sync_enabled")
            setupAutoSyncTimer()
        }
    }
    
    var googleSyncIntervalMinutes: Int = 30 {
        didSet {
            UserDefaults.standard.set(googleSyncIntervalMinutes, forKey: "google_sync_interval_minutes")
            setupAutoSyncTimer()
        }
    }
    
    // Instant Sync (Immediate Sync on Save) Configuration
    var googleInstantSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(googleInstantSyncEnabled, forKey: "google_instant_sync_enabled")
        }
    }
    
    @ObservationIgnored
    var onTriggerAutoSync: (() -> Void)? = nil
    
    @ObservationIgnored
    private var autoSyncTimer: Timer?
    
    @ObservationIgnored
    private var saveObserver: NSObjectProtocol?
    
    @ObservationIgnored
    private var instantSyncWorkItem: DispatchWorkItem?
    
    init() {
        self.googleSpreadsheetID = UserDefaults.standard.string(forKey: "google_spreadsheet_id") ?? ""
        self.googleSpreadsheetName = UserDefaults.standard.string(forKey: "google_spreadsheet_name") ?? ""
        self.googleLastSyncTime = UserDefaults.standard.double(forKey: "google_last_sync_time")
        self.googleAutoSyncEnabled = UserDefaults.standard.bool(forKey: "google_auto_sync_enabled")
        let savedInterval = UserDefaults.standard.integer(forKey: "google_sync_interval_minutes")
        self.googleSyncIntervalMinutes = savedInterval > 0 ? savedInterval : 30
        self.googleInstantSyncEnabled = UserDefaults.standard.bool(forKey: "google_instant_sync_enabled")
        
        setupSaveObserver()
    }
    
    deinit {
        if let observer = saveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setupSaveObserver() {
        if let observer = saveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        saveObserver = nil
        
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDatabaseSave()
        }
    }
    
    private func handleDatabaseSave() {
        guard googleInstantSyncEnabled && !googleSpreadsheetID.isEmpty else { return }
        
        // Cancel any pending instant sync
        instantSyncWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            print("[AppState] Instant sync debouncer fired. Triggering immediate upload to Google Sheets...")
            self?.onTriggerAutoSync?()
        }
        
        instantSyncWorkItem = workItem
        // Debounce for 3 seconds to aggregate edits and avoid API spam
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
    
    func setupAutoSyncTimer() {
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
        
        guard googleAutoSyncEnabled && !googleSpreadsheetID.isEmpty else { return }
        
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkAndTriggerAutoSync()
        }
    }
    
    private func checkAndTriggerAutoSync() {
        guard googleAutoSyncEnabled && !googleSpreadsheetID.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let intervalSeconds = Double(googleSyncIntervalMinutes * 60)
        
        if now - googleLastSyncTime >= intervalSeconds {
            print("[AppState] Interval elapsed. Triggering auto background sync...")
            DispatchQueue.main.async { [weak self] in
                self?.onTriggerAutoSync?()
            }
        }
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
