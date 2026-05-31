//
//  CloudKitService.swift
//  AICustomerResverSystem
//

import Foundation
import CloudKit
import Observation

@Observable
@MainActor
final class CloudKitService {
    static let shared = CloudKitService()
    
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var isChecking = false
    var lastErrorDescription: String? = nil
    var lastChecked: Date? = nil
    
    private init() {
        // Run initial check
        Task {
            await checkAccountStatus()
        }
    }
    
    func checkAccountStatus() async {
        isChecking = true
        lastErrorDescription = nil
        
        // Safety Check: Verify if the iCloud capability/entitlement is configured in Xcode.
        // If this returns nil, it means iCloud capability is missing in entitlements or disabled,
        // so we bypass calling CKContainer.default() entirely to avoid fatal process crashes.
        guard FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil else {
            self.accountStatus = .noAccount
            self.lastErrorDescription = "系統檢測到專案尚未啟用 iCloud 權限 (com.apple.developer.icloud-services)。請在 Xcode 中新增 iCloud (CloudKit) 服務權限。"
            self.lastChecked = Date()
            isChecking = false
            return
        }
        
        do {
            let status = try await CKContainer.default().accountStatus()
            self.accountStatus = status
            self.lastChecked = Date()
            print("[CloudKitService] iCloud account status checked: \(statusString(for: status))")
        } catch {
            self.accountStatus = .couldNotDetermine
            self.lastErrorDescription = error.localizedDescription
            self.lastChecked = Date()
            print("[CloudKitService] Failed to check iCloud account status: \(error.localizedDescription)")
        }
        
        isChecking = false
    }
    
    var isCloudAvailable: Bool {
        accountStatus == .available
    }
    
    var statusTitle: String {
        statusString(for: accountStatus)
    }
    
    var statusIcon: String {
        switch accountStatus {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "xmark.icloud.fill"
        case .restricted:
            return "lock.icloud.fill"
        case .couldNotDetermine:
            return "exclamationmark.icloud.fill"
        case .temporarilyUnavailable:
            return "exclamationmark.icloud.fill"
        @unknown default:
            return "icloud.slash.fill"
        }
    }
    
    var statusDescription: String {
        switch accountStatus {
        case .available:
            return "iCloud 連線正常。您的資料庫將在啟用雲端模式後與您的 Apple 雲端同步。"
        case .noAccount:
            return "未在裝置上檢測到 iCloud 帳戶。請前往系統「設定」並登入您的 Apple ID 以啟動雲端自動備份與多端同步功能。"
        case .restricted:
            return "iCloud 功能受到家長控制或企業設定之限制，無法進行跨端同步。"
        case .couldNotDetermine:
            return "連線遭遇未知的臨時問題或網路中斷，請重試或檢查裝置的網路狀態。"
        case .temporarilyUnavailable:
            return "iCloud 服務目前暫時不可用，可能由於伺服器維護或短暫連線中斷，請稍後重試。"
        @unknown default:
            return "未知的 iCloud 狀態。"
        }
    }
    
    private func statusString(for status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "帳戶可用 (Available)"
        case .noAccount:
            return "未登入 iCloud 帳戶"
        case .restricted:
            return "iCloud 帳戶存取受限"
        case .couldNotDetermine:
            return "無法確定 iCloud 帳戶狀態"
        case .temporarilyUnavailable:
            return "暫時不可用 (Temporarily Unavailable)"
        @unknown default:
            return "未知帳戶狀態"
        }
    }
}
