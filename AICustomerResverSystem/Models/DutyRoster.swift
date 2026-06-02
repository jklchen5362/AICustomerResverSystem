//  DutyRoster.swift
//  AICustomerResverSystem
//

import Foundation
import SwiftData

@Model
final class DutyRoster {
    var rosterID: String
    var date: Date
    var onDutyDoctors: [String]
    var onDutyManagers: [String]
    var onDutyConsultants: [String]
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var branch: Branch?
    
    init(
        rosterID: String = "RST-" + UUID().uuidString.prefix(6).uppercased(),
        date: Date = Date(),
        onDutyDoctors: [String] = [],
        onDutyManagers: [String] = [],
        onDutyConsultants: [String] = [],
        notes: String = ""
    ) {
        self.rosterID = rosterID
        self.date = date
        self.onDutyDoctors = onDutyDoctors
        self.onDutyManagers = onDutyManagers
        self.onDutyConsultants = onDutyConsultants
        self.notes = notes
    }
}
