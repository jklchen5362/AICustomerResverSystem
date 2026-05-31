
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
                    loadSampleDataIfNeeded()
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
