
//  TreatmentPackage.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class TreatmentPackage {
    @Attribute(.unique) var packageID: String
    var treatmentName: String
    var totalSessions: Int
    var sessionsUsed: Int
    var purchaseAmount: Double
    var purchaseDate: Date
    var expirationDate: Date?
    var salesConsultant: String
    
    // Relationships
    var customer: Customer?
    
    @Relationship(deleteRule: .nullify)
    var purchaseBranch: Branch?
    
    @Relationship(deleteRule: .cascade, inverse: \ConsumptionRecord.package)
    var consumptions: [ConsumptionRecord] = []
    
    init(
        packageID: String = "PKG-" + UUID().uuidString.prefix(6).uppercased(),
        treatmentName: String,
        totalSessions: Int,
        sessionsUsed: Int = 0,
        purchaseAmount: Double,
        purchaseDate: Date = Date(),
        expirationDate: Date? = nil,
        salesConsultant: String = ""
    ) {
        self.packageID = packageID
        self.treatmentName = treatmentName
        self.totalSessions = totalSessions
        self.sessionsUsed = sessionsUsed
        self.purchaseAmount = purchaseAmount
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.salesConsultant = salesConsultant
    }
    
    // MARK: - Computed Properties
    var remainingSessions: Int {
        max(0, totalSessions - sessionsUsed)
    }
    
    var remainingPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(remainingSessions) / Double(totalSessions)
    }
    
    var isActive: Bool {
        remainingSessions > 0 && !isExpired
    }
    
    var isExpired: Bool {
        guard let exp = expirationDate else { return false }
        return exp < Date()
    }
    
    var isCompleted: Bool {
        remainingSessions == 0
    }
    
    var statusText: String {
        if isExpired { return "已過期" }
        if isCompleted { return "已完成" }
        return "使用中"
    }
    
    var daysUntilExpiration: Int? {
        guard let exp = expirationDate else { return nil }
        return exp.daysUntil
    }
    
    var perSessionPrice: Double {
        guard totalSessions > 0 else { return 0 }
        return purchaseAmount / Double(totalSessions)
    }
    
    var customerName: String {
        customer?.fullName ?? "未指定"
    }
    
    var branchName: String {
        purchaseBranch?.name ?? "未指定"
    }
}
