//  AuthViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class AuthViewModel {
    var currentUser: UserAccount? = nil
    var isAuthenticated = false
    var isBiometricEnabled = false
    
    init() {}
    
    @MainActor
    func login(context: ModelContext) {
        // Fetch or create first mock admin user
        do {
            let desc = FetchDescriptor<UserAccount>()
            let accounts = (try? context.fetch(desc)) ?? []
            
            if let existing = accounts.first {
                self.currentUser = existing
                self.isAuthenticated = true
            } else {
                let defaultAdmin = UserAccount(
                    username: "jeff_consultant",
                    displayName: "張晉豪 Jeff",
                    email: "jeff@aestheticclinic.tw",
                    role: .admin
                )
                context.insert(defaultAdmin)
                try context.save()
                
                self.currentUser = defaultAdmin
                self.isAuthenticated = true
            }
        } catch {
            print("Failed to initialize authentication: \(error)")
        }
    }
    
    @MainActor
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
