//
//  DatabaseType.swift
//  AICustomerResverSystem
//

import Foundation

enum DatabaseType: String, CaseIterable, Identifiable, Codable {
    case localOnly = "localOnly"
    case cloudKit = "cloudKit"
    case googleSheets = "googleSheets"
    case dualSync = "dualSync"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .localOnly:
            return "離線本機資料庫 (Local Only)"
        case .cloudKit:
            return "iCloud 雲端同步 (CloudKit)"
        case .googleSheets:
            return "Google 試算表同步 (Google Sheets)"
        case .dualSync:
            return "雙重同步 (iCloud + Google)"
        }
    }
    
    var subtitle: String {
        switch self {
        case .localOnly:
            return "僅限此本機裝置安全儲存"
        case .cloudKit:
            return "跨多部 Apple 裝置自動對接"
        case .googleSheets:
            return "即時備份與鏡像 Google 試算表"
        case .dualSync:
            return "同時同步備份至 iCloud 與 Google"
        }
    }
    
    var description: String {
        switch self {
        case .localOnly:
            return "所有客戶檔案與療程數據皆以極速安全地儲存在此本機裝置內。不需登入雲端帳戶或連接網路，適合注重極致資料安全與隱私隱密的場景。"
        case .cloudKit:
            return "使用您的個人 iCloud 私有雲端儲存空間。所有資料在您的個人多部蘋果裝置間自動對接同步（例如 iPhone 與 iPad），安全防丟失。"
        case .googleSheets:
            return "將您的本機 CRM 數據鏡像備份至 Google 試算表。方便您在 Mac/PC 瀏覽器端直接開啟、共享、統計或編輯您的客戶與排程。"
        case .dualSync:
            return "融合 Apple 與 Google 雲端生態之最強防護！同時啟用本機 iCloud 跨端對接，並由背景定時或手動將數據同步鏡像至 Google Sheets 試算表。"
        }
    }
    
    var iconName: String {
        switch self {
        case .localOnly:
            return "iphone"
        case .cloudKit:
            return "cloud.fill"
        case .googleSheets:
            return "tablecells.fill"
        case .dualSync:
            return "arrow.trianglehead.2.counterclockwise.rotate.90.icloud.fill"
        }
    }
}
