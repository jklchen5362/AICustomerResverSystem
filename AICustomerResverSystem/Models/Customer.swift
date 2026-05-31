
//  Customer.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class Customer {
    @Attribute(.unique) var customerID: String
    var fullName: String
    var gender: Gender
    var birthday: Date?
    var phone: String
    var email: String
    var lineID: String
    var address: String
    var vipLevel: VIPLevel
    var notes: String
    
    // Medical Information
    var allergyHistory: String
    var treatmentHistory: String
    var skinType: SkinType?
    var consultationNotes: String
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var profileImageData: Data?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TreatmentPackage.customer)
    var packages: [TreatmentPackage] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Appointment.customer)
    var appointments: [Appointment] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Invoice.customer)
    var invoices: [Invoice] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ConsumptionRecord.customer)
    var consumptions: [ConsumptionRecord] = []
    
    @Relationship(deleteRule: .cascade, inverse: \AppNotification.customer)
    var notifications: [AppNotification] = []
    
    init(
        customerID: String = UUID().uuidString.prefix(8).uppercased() + "",
        fullName: String,
        gender: Gender = .female,
        birthday: Date? = nil,
        phone: String = "",
        email: String = "",
        lineID: String = "",
        address: String = "",
        vipLevel: VIPLevel = .regular,
        notes: String = "",
        allergyHistory: String = "",
        treatmentHistory: String = "",
        skinType: SkinType? = nil,
        consultationNotes: String = ""
    ) {
        self.customerID = customerID
        self.fullName = fullName
        self.gender = gender
        self.birthday = birthday
        self.phone = phone
        self.email = email
        self.lineID = lineID
        self.address = address
        self.vipLevel = vipLevel
        self.notes = notes
        self.allergyHistory = allergyHistory
        self.treatmentHistory = treatmentHistory
        self.skinType = skinType
        self.consultationNotes = consultationNotes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    var activePackages: [TreatmentPackage] {
        packages.filter { $0.remainingSessions > 0 && ($0.expirationDate ?? .distantFuture) > Date() }
    }
    
    var totalRemainingSessions: Int {
        activePackages.reduce(0) { $0 + $1.remainingSessions }
    }
    
    var totalSpent: Double {
        invoices.reduce(0) { $0 + $1.amount }
    }
    
    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.appointmentDate >= Date() && $0.status != .cancelled }
            .sorted { $0.appointmentDate < $1.appointmentDate }
    }
    
    var lastVisitDate: Date? {
        appointments
            .filter { $0.status == .completed }
            .sorted { $0.appointmentDate > $1.appointmentDate }
            .first?.appointmentDate
    }
    
    var initials: String {
        let names = fullName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1)) + String(names[1].prefix(1))
        }
        return String(fullName.prefix(1))
    }
    
    var displayAge: String? {
        guard let birthday = birthday else { return nil }
        return "\(birthday.age)歲"
    }
}
