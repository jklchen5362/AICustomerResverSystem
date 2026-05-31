
//  Constants.swift
//  AICustomerResverSystem

import SwiftUI

// MARK: - App Constants
enum AppConstants {
    static let appName = "醫美智能管理系統"
    static let appNameEN = "AI Beauty CRM"
    static let version = "1.0.0"
    static let defaultCurrency = "TWD"
    static let currencySymbol = "NT$"
    static let maxPhotoSize: CGFloat = 1024
    static let animationDuration: Double = 0.35
    static let pageSize: Int = 20
}

// MARK: - Gender
enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .male: return "男 Male"
        case .female: return "女 Female"
        case .other: return "其他 Other"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "person.fill"
        }
    }
}

// MARK: - VIP Level
enum VIPLevel: String, Codable, CaseIterable, Identifiable {
    case regular = "regular"
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .regular: return "一般會員"
        case .bronze: return "銅卡 Bronze"
        case .silver: return "銀卡 Silver"
        case .gold: return "金卡 Gold"
        case .platinum: return "白金卡 Platinum"
        case .diamond: return "鑽石卡 Diamond"
        }
    }
    
    var color: Color {
        switch self {
        case .regular: return AppTheme.Colors.textSecondary
        case .bronze: return AppTheme.Colors.vipBronze
        case .silver: return AppTheme.Colors.vipSilver
        case .gold: return AppTheme.Colors.vipGold
        case .platinum: return AppTheme.Colors.vipPlatinum
        case .diamond: return Color(hex: "B9F2FF")
        }
    }
    
    var icon: String {
        switch self {
        case .regular: return "person.fill"
        case .bronze: return "star.fill"
        case .silver: return "star.fill"
        case .gold: return "crown.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }
}

// MARK: - Appointment Status
enum AppointmentStatus: String, Codable, CaseIterable, Identifiable {
    case confirmed = "confirmed"
    case arrived = "arrived"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "noShow"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .confirmed: return "已確認 Confirmed"
        case .arrived: return "已到達 Arrived"
        case .completed: return "已完成 Completed"
        case .cancelled: return "已取消 Cancelled"
        case .noShow: return "未到 No Show"
        }
    }
    
    var shortName: String {
        switch self {
        case .confirmed: return "已確認"
        case .arrived: return "已到達"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .noShow: return "未到"
        }
    }
    
    var color: Color {
        switch self {
        case .confirmed: return AppTheme.Colors.statusConfirmed
        case .arrived: return AppTheme.Colors.statusArrived
        case .completed: return AppTheme.Colors.statusCompleted
        case .cancelled: return AppTheme.Colors.statusCancelled
        case .noShow: return AppTheme.Colors.statusNoShow
        }
    }
    
    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle.fill"
        case .arrived: return "figure.walk.arrival"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "person.fill.questionmark"
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cash = "cash"
    case creditCard = "creditCard"
    case bankTransfer = "bankTransfer"
    case linePay = "linePay"
    case applePay = "applePay"
    case installment = "installment"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cash: return "現金 Cash"
        case .creditCard: return "信用卡 Credit Card"
        case .bankTransfer: return "銀行轉帳 Transfer"
        case .linePay: return "LINE Pay"
        case .applePay: return "Apple Pay"
        case .installment: return "分期付款 Installment"
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .creditCard: return "creditcard.fill"
        case .bankTransfer: return "building.columns.fill"
        case .linePay: return "message.fill"
        case .applePay: return "apple.logo"
        case .installment: return "calendar.badge.clock"
        }
    }
}

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case admin = "admin"
    case doctor = "doctor"
    case consultant = "consultant"
    case receptionist = "receptionist"
    case beautician = "beautician"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .admin: return "管理員 Admin"
        case .doctor: return "醫師 Doctor"
        case .consultant: return "諮詢師 Consultant"
        case .receptionist: return "櫃檯 Receptionist"
        case .beautician: return "美容師 Beautician"
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "shield.checkered"
        case .doctor: return "stethoscope"
        case .consultant: return "person.badge.clock.fill"
        case .receptionist: return "desktopcomputer"
        case .beautician: return "sparkles"
        }
    }
    
    var permissions: Set<Permission> {
        switch self {
        case .admin: return Set(Permission.allCases)
        case .doctor: return [.viewCustomers, .viewAppointments, .editAppointments, .viewPackages, .addConsumption, .viewReports]
        case .consultant: return [.viewCustomers, .editCustomers, .viewAppointments, .editAppointments, .viewPackages, .editPackages, .addConsumption, .viewFinancials]
        case .receptionist: return [.viewCustomers, .editCustomers, .viewAppointments, .editAppointments, .viewPackages]
        case .beautician: return [.viewCustomers, .viewAppointments, .viewPackages, .addConsumption]
        }
    }
}

// MARK: - Permissions
enum Permission: String, CaseIterable {
    case viewCustomers
    case editCustomers
    case deleteCustomers
    case viewAppointments
    case editAppointments
    case deleteAppointments
    case viewPackages
    case editPackages
    case deletePackages
    case addConsumption
    case viewFinancials
    case editFinancials
    case viewReports
    case manageUsers
    case manageBranches
    case manageSettings
}

// MARK: - Notification Type
enum NotificationType: String, Codable, CaseIterable, Identifiable {
    case appointmentReminder = "appointmentReminder"
    case packageExpiration = "packageExpiration"
    case birthdayGreeting = "birthdayGreeting"
    case followUpReminder = "followUpReminder"
    case systemAlert = "systemAlert"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .appointmentReminder: return "預約提醒"
        case .packageExpiration: return "療程到期提醒"
        case .birthdayGreeting: return "生日祝福"
        case .followUpReminder: return "回訪提醒"
        case .systemAlert: return "系統通知"
        }
    }
    
    var icon: String {
        switch self {
        case .appointmentReminder: return "calendar.badge.exclamationmark"
        case .packageExpiration: return "clock.badge.exclamationmark.fill"
        case .birthdayGreeting: return "gift.fill"
        case .followUpReminder: return "arrow.trianglehead.2.counterclockwise"
        case .systemAlert: return "bell.badge.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .appointmentReminder: return AppTheme.Colors.info
        case .packageExpiration: return AppTheme.Colors.warning
        case .birthdayGreeting: return AppTheme.Colors.accent
        case .followUpReminder: return AppTheme.Colors.accentSecondary
        case .systemAlert: return AppTheme.Colors.danger
        }
    }
}

// MARK: - Skin Type
enum SkinType: String, Codable, CaseIterable, Identifiable {
    case dry = "dry"
    case oily = "oily"
    case combination = "combination"
    case sensitive = "sensitive"
    case normal = "normal"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dry: return "乾性 Dry"
        case .oily: return "油性 Oily"
        case .combination: return "混合性 Combination"
        case .sensitive: return "敏感性 Sensitive"
        case .normal: return "中性 Normal"
        }
    }
}

// MARK: - Tab Items
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case customers = "customers"
    case appointments = "appointments"
    case aiAssistant = "aiAssistant"
    case more = "more"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .dashboard: return "儀表板"
        case .customers: return "客戶"
        case .appointments: return "預約"
        case .aiAssistant: return "AI 助理"
        case .more: return "更多"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .customers: return "person.2.fill"
        case .appointments: return "calendar"
        case .aiAssistant: return "sparkles"
        case .more: return "ellipsis.circle.fill"
        }
    }
}
