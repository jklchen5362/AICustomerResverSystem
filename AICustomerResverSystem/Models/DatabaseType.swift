//
//  DatabaseType.swift
//  AICustomerResverSystem
//

import Foundation

enum DatabaseType: String, CaseIterable, Identifiable, Codable {
    case localOnly = "localOnly"
    case privateCloud = "privateCloud"
    case sharedCloud = "sharedCloud"
    case publicCloud = "publicCloud"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .localOnly:
            return "離線本機資料庫"
        case .privateCloud:
            return "個人私有雲 (Private)"
        case .sharedCloud:
            return "共享協作雲 (Shared)"
        case .publicCloud:
            return "公共大眾雲 (Public)"
        }
    }
    
    var subtitle: String {
        switch self {
        case .localOnly:
            return "僅限此裝置"
        case .privateCloud:
            return "iCloud 個人同步"
        case .sharedCloud:
            return "團隊共享協作"
        case .publicCloud:
            return "公共公開儲存"
        }
    }
    
    var description: String {
        switch self {
        case .localOnly:
            return "所有資料皆以極速安全地儲存在此本機裝置內。不需登入 iCloud 或連接網路，適合注重極致隱私或純單機作業的場景。"
        case .privateCloud:
            return "使用您的 iCloud 私有雲端儲存空間。所有資料在您的個人多部蘋果裝置間自動同步（例如 iPhone 與 iPad），其他任何人皆無法讀取。"
        case .sharedCloud:
            return "適合跨團隊協作。資料儲存於 iCloud 共享資料庫，您可以邀請其他系統用戶共同檢視與維護同一個客戶管理平台。"
        case .publicCloud:
            return "資料儲存於 iCloud 公開區塊。所有下載此應用的用戶在擁有權限的情況下均可讀取公共資料，常用於全局共享資訊或全平台公告。"
        }
    }
    
    var iconName: String {
        switch self {
        case .localOnly:
            return "iphone"
        case .privateCloud:
            return "cloud.fill"
        case .sharedCloud:
            return "person.3.sequence.fill"
        case .publicCloud:
            return "globe.asia.australia.fill"
        }
    }
}
