//
//  ModelContainerFactory.swift
//  AICustomerResverSystem
//

import Foundation
import SwiftData
import CloudKit

struct ModelContainerFactory {
    static let schema = Schema([
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
    
    @MainActor
    static func createContainer(for type: DatabaseType) -> ModelContainer {
        let configuration: ModelConfiguration
        
        switch type {
        case .localOnly:
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        case .privateCloud:
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        case .sharedCloud:
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.xcode.AICustomerResverSystem.shared")
            )
        case .publicCloud:
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.xcode.AICustomerResverSystem.public")
            )
        }
        
        do {
            print("[SwiftData] Attempting to initialize ModelContainer for database type: \(type.rawValue)")
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("[SwiftData] Error initializing ModelContainer for \(type.rawValue): \(error.localizedDescription)")
            print("[SwiftData] Falling back to Local Only configuration.")
            
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("[SwiftData] Fatal error creating fallback ModelContainer: \(error)")
            }
        }
    }
}
