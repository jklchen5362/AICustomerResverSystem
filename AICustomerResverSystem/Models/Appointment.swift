
//  Appointment.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class Appointment {
    @Attribute(.unique) var appointmentID: String
    var treatmentItem: String
    var doctor: String
    var beautician: String
    var appointmentDate: Date
    var startTime: Date
    var endTime: Date
    var status: AppointmentStatus
    var notes: String
    
    // Relationships
    var customer: Customer?
    
    @Relationship(deleteRule: .nullify)
    var branch: Branch?
    
    init(
        appointmentID: String = "APT-" + UUID().uuidString.prefix(6).uppercased(),
        treatmentItem: String,
        doctor: String = "",
        beautician: String = "",
        appointmentDate: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date().addingTimeInterval(3600),
        status: AppointmentStatus = .confirmed,
        notes: String = ""
    ) {
        self.appointmentID = appointmentID
        self.treatmentItem = treatmentItem
        self.doctor = doctor
        self.beautician = beautician
        self.appointmentDate = appointmentDate
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    var customerName: String {
        customer?.fullName ?? "未指定"
    }
    
    var branchName: String {
        branch?.name ?? "未指定"
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var durationMinutes: Int {
        Int(duration / 60)
    }
    
    var formattedTimeRange: String {
        "\(startTime.formattedTime) - \(endTime.formattedTime)"
    }
    
    var isUpcoming: Bool {
        appointmentDate >= Date() && status == .confirmed
    }
    
    var isPast: Bool {
        appointmentDate < Date()
    }
    
    var isToday: Bool {
        appointmentDate.isToday
    }
}
