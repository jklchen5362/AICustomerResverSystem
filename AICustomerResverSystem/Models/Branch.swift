
//  Branch.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class Branch {
    var branchID: String
    var name: String
    var address: String
    var phone: String
    var manager: String
    var isActive: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Appointment.branch)
    var appointments: [Appointment] = []
    
    @Relationship(deleteRule: .nullify, inverse: \TreatmentPackage.purchaseBranch)
    var packages: [TreatmentPackage] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Invoice.branch)
    var invoices: [Invoice] = []
    
    @Relationship(deleteRule: .nullify, inverse: \ConsumptionRecord.branch)
    var consumptionRecords: [ConsumptionRecord] = []
    
    init(
        branchID: String = "BR-" + UUID().uuidString.prefix(4).uppercased(),
        name: String,
        address: String = "",
        phone: String = "",
        manager: String = "",
        isActive: Bool = true
    ) {
        self.branchID = branchID
        self.name = name
        self.address = address
        self.phone = phone
        self.manager = manager
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    // MARK: - Computed
    var totalRevenue: Double {
        invoices.reduce(0) { $0 + $1.amount }
    }
    
    var activePackageCount: Int {
        packages.filter { $0.isActive }.count
    }
    
    var todayAppointments: [Appointment] {
        appointments.filter { $0.appointmentDate.isToday }
    }
}
