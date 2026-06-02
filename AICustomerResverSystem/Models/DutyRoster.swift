//  DutyRoster.swift
//  AICustomerResverSystem
//

import Foundation
import SwiftData

@Model
final class DutyRoster {
    var rosterID: String
    var date: Date
    var onDutyDoctor: String
    var onDutyManager: String
    var onDutyConsultant: String
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var branch: Branch?
    
    init(
        rosterID: String = "RST-" + UUID().uuidString.prefix(6).uppercased(),
        date: Date = Date(),
        onDutyDoctor: String = "",
        onDutyManager: String = "",
        onDutyConsultant: String = "",
        notes: String = ""
    ) {
        self.rosterID = rosterID
        self.date = date
        self.onDutyDoctor = onDutyDoctor
        self.onDutyManager = onDutyManager
        self.onDutyConsultant = onDutyConsultant
        self.notes = notes
    }
}
