
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
    
    // Reminder Options
    var reminderLeadTimeSeconds: Int
    var reminderSoundTypeRaw: String
    var reminderSpeechText: String
    
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
        notes: String = "",
        reminderLeadTimeSeconds: Int = 3600,
        reminderSoundTypeRaw: String = "systemDefault",
        reminderSpeechText: String = ""
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
        self.reminderLeadTimeSeconds = reminderLeadTimeSeconds
        self.reminderSoundTypeRaw = reminderSoundTypeRaw
        self.reminderSpeechText = reminderSpeechText
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
    
    // MARK: - Reminder Helpers
    var reminderLeadTime: ReminderLeadTime {
        get { ReminderLeadTime(rawValue: reminderLeadTimeSeconds) ?? .oneHour }
        set { reminderLeadTimeSeconds = newValue.rawValue }
    }
    
    var reminderSoundType: ReminderSoundType {
        get { ReminderSoundType(rawValue: reminderSoundTypeRaw) ?? .systemDefault }
        set { reminderSoundTypeRaw = newValue.rawValue }
    }
}

enum ReminderLeadTime: Int, CaseIterable, Identifiable, Codable, Sendable {
    case none = 0
    case oneHour = 3600
    case twoHours = 7200
    case twentyFourHours = 86400
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "無提醒"
        case .oneHour: return "前 1 小時"
        case .twoHours: return "前 2 小時"
        case .twentyFourHours: return "前 24 小時"
        }
    }
}

enum ReminderSoundType: String, CaseIterable, Identifiable, Codable, Sendable {
    case systemDefault = "systemDefault"
    case classicChime = "classicChime"
    case voiceSpeech = "voiceSpeech"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .systemDefault: return "系統預設通知聲"
        case .classicChime: return "經典風鈴"
        case .voiceSpeech: return "專屬 AI 語音唸讀"
        }
    }
}
