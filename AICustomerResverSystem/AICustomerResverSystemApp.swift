//
//  AICustomerResverSystemApp.swift
//  AICustomerResverSystem
//
//  Created by Jeff on 2026/5/31.
//

import SwiftUI
import SwiftData

@main
struct AICustomerResverSystemApp: App {
    @State private var appState = AppState()
    private let notificationDelegate = NotificationDelegate()
    
    // Bind to the AppStorage selection to observe changes
    @AppStorage("databaseSelection") private var databaseSelection: String = DatabaseType.localOnly.rawValue
    
    // Dynamic hot-swappable model container
    @State private var modelContainer: ModelContainer
    
    init() {
        // Read the initial selection directly from UserDefaults to set up the container
        let initialSelection = UserDefaults.standard.string(forKey: "databaseSelection") ?? DatabaseType.localOnly.rawValue
        let initialType = DatabaseType(rawValue: initialSelection) ?? .localOnly
        
        // Setup initial container matching preference
        let container = ModelContainerFactory.createContainer(for: initialType)
        _modelContainer = State(initialValue: container)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .onAppear {
                    setupAppearance()
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    loadSampleDataIfNeeded()
                    
                    // Proactively request local notification permissions
                    Task {
                        _ = await NotificationService.shared.requestPermission()
                    }
                }
                .onChange(of: databaseSelection) { oldValue, newValue in
                    let type = DatabaseType(rawValue: newValue) ?? .localOnly
                    print("[App] Database selection changed from \(oldValue) to \(newValue). Swapping SwiftData Container...")
                    
                    // Instantiate new container matching selection
                    let newContainer = ModelContainerFactory.createContainer(for: type)
                    
                    // Update state to propagate down to environment
                    self.modelContainer = newContainer
                    
                    // Automatically seed sample data if container is fresh and empty
                    let context = newContainer.mainContext
                    let descriptor = FetchDescriptor<Customer>()
                    let count = (try? context.fetchCount(descriptor)) ?? 0
                    if count == 0 {
                        print("[App] Hot-swapped container is empty. Seeding sample data...")
                        SampleDataService.loadSampleData(into: context)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
    
    private func setupAppearance() {
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().standardAppearance = navAppearance
    }
    
    @MainActor
    private func loadSampleDataIfNeeded() {
        guard !appState.hasLoadedSampleData else { return }
        let context = modelContainer.mainContext
        
        // Check if data already exists
        let descriptor = FetchDescriptor<Customer>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            SampleDataService.loadSampleData(into: context)
        }
        appState.hasLoadedSampleData = true
    }
}

// MARK: - NotificationDelegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let speechText = userInfo["speechText"] as? String {
            DispatchQueue.main.async {
                SpeechService.shared.speak(speechText)
            }
        }
        completionHandler([.banner, .list, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let speechText = userInfo["speechText"] as? String {
            DispatchQueue.main.async {
                SpeechService.shared.speak(speechText)
            }
        }
        completionHandler()
    }
}
