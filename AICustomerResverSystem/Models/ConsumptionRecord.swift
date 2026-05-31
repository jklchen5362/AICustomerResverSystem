
//  ConsumptionRecord.swift
//  AICustomerResverSystem

import Foundation
import SwiftData

@Model
final class ConsumptionRecord {
    var recordID: String
    var date: Date
    var treatmentName: String
    var sessionsConsumed: Int
    var operatorName: String
    var beforePhotoData: Data?
    var afterPhotoData: Data?
    var signatureData: Data?
    var notes: String
    
    // Relationships
    var customer: Customer?
    var package: TreatmentPackage?
    
    @Relationship(deleteRule: .nullify)
    var branch: Branch?
    
    init(
        recordID: String = "CR-" + UUID().uuidString.prefix(6).uppercased(),
        date: Date = Date(),
        treatmentName: String,
        sessionsConsumed: Int = 1,
        operatorName: String = "",
        notes: String = ""
    ) {
        self.recordID = recordID
        self.date = date
        self.treatmentName = treatmentName
        self.sessionsConsumed = sessionsConsumed
        self.operatorName = operatorName
        self.notes = notes
    }
    
    var customerName: String {
        customer?.fullName ?? "未指定"
    }
    
    var branchName: String {
        branch?.name ?? "未指定"
    }
    
    var packageName: String {
        package?.treatmentName ?? treatmentName
    }
    
    var hasBeforePhoto: Bool {
        beforePhotoData != nil
    }
    
    var hasAfterPhoto: Bool {
        afterPhotoData != nil
    }
}
