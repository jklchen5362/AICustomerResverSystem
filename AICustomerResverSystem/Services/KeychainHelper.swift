//
//  KeychainHelper.swift
//  AICustomerResverSystem
//

import Foundation
import Security

struct GoogleCredentials: Codable, Equatable {
    let email: String
    let displayName: String
    var accessToken: String
    let refreshToken: String
    var expiresAt: Date
    
    var isExpired: Bool {
        // Expired if current date is past expiresAt minus a 5-minute safety buffer
        Date().addingTimeInterval(300) > expiresAt
    }
}

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private let serviceName = "com.xcode.AICustomerResverSystem.google-oauth"
    private let accountsKey = "com.xcode.AICustomerResverSystem.google-accounts"
    
    // MARK: - Generic Keychain Access
    
    private func save(_ data: Data, account: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func read(account: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    private func delete(account: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Typed Google Credentials
    
    func saveCredentials(_ credentials: GoogleCredentials) -> Bool {
        do {
            let data = try JSONEncoder().encode(credentials)
            let success = save(data, account: credentials.email)
            if success {
                registerAccount(credentials.email)
            }
            return success
        } catch {
            print("[KeychainHelper] Error encoding credentials: \(error.localizedDescription)")
            return false
        }
    }
    
    func readCredentials(email: String) -> GoogleCredentials? {
        guard let data = read(account: email) else { return nil }
        do {
            return try JSONDecoder().decode(GoogleCredentials.self, from: data)
        } catch {
            print("[KeychainHelper] Error decoding credentials for \(email): \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteCredentials(email: String) -> Bool {
        let success = delete(account: email)
        if success {
            unregisterAccount(email)
        }
        return success
    }
    
    // MARK: - Account List Management
    
    func getRegisteredAccounts() -> [String] {
        UserDefaults.standard.stringArray(forKey: accountsKey) ?? []
    }
    
    private func registerAccount(_ email: String) {
        var accounts = getRegisteredAccounts()
        if !accounts.contains(email) {
            accounts.append(email)
            UserDefaults.standard.set(accounts, forKey: accountsKey)
        }
    }
    
    private func unregisterAccount(_ email: String) {
        var accounts = getRegisteredAccounts()
        if let index = accounts.firstIndex(of: email) {
            accounts.remove(at: index)
            UserDefaults.standard.set(accounts, forKey: accountsKey)
        }
    }
}
