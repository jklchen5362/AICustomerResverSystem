//  ConsumptionViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class ConsumptionViewModel {
    var searchText: String = ""
    
    init() {}
    
    @MainActor
    func recordConsumption(
        package: TreatmentPackage,
        sessions: Int,
        operatorName: String,
        branch: Branch?,
        notes: String,
        context: ModelContext
    ) {
        // 1. Create consumption record
        let record = ConsumptionRecord(
            treatmentName: package.treatmentName,
            sessionsConsumed: sessions,
            operatorName: operatorName,
            notes: notes
        )
        
        record.customer = package.customer
        record.package = package
        record.branch = branch
        context.insert(record)
        
        // 2. Auto-deduct sessions
        package.sessionsUsed += sessions
        
        // 3. Save
        try? context.save()
        
        // 4. Trigger follow-up/warning notifications if sessions running low
        if let customer = package.customer {
            if package.remainingSessions <= 2 && package.remainingSessions > 0 {
                let warningNotif = AppNotification(
                    type: .packageExpiration,
                    title: "療程堂數即將用畢提醒",
                    message: "客戶 \(customer.fullName) 的 \(package.treatmentName) 僅剩餘 \(package.remainingSessions) 堂。建議在下次預約時主動推銷續購套裝方案！",
                    scheduledDate: Date()
                )
                warningNotif.customer = customer
                context.insert(warningNotif)
                try? context.save()
            }
        }
    }
    
    @MainActor
    func deleteRecord(_ record: ConsumptionRecord, context: ModelContext) {
        if let package = record.package {
            // Restore sessions used
            package.sessionsUsed = max(0, package.sessionsUsed - record.sessionsConsumed)
        }
        context.delete(record)
        try? context.save()
    }
}
