
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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Customer.self,
            TreatmentPackage.self,
            Appointment.self,
            Branch.self,
            ConsumptionRecord.self,
            Invoice.self,
            AppNotification.self,
            UserAccount.self,
            ChatMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
        }
        .modelContainer(sharedModelContainer)
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
        let context = sharedModelContainer.mainContext
        
        // Check if data already exists
        let descriptor = FetchDescriptor<Customer>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        
        if count == 0 {
            SampleDataService.loadSampleData(into: context)
            appState.hasLoadedSampleData = true
        }
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
