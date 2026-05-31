//  BranchViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

@Observable
class BranchViewModel {
    init() {}
    
    @MainActor
    func saveBranch(_ branch: Branch, context: ModelContext) {
        context.insert(branch)
        try? context.save()
    }
    
    @MainActor
    func deleteBranch(_ branch: Branch, context: ModelContext) {
        context.delete(branch)
        try? context.save()
    }
}

enum FinancialPeriod: String, CaseIterable, Identifiable {
    case thisMonth = "本月"
    case lastMonth = "上月"
    case thisQuarter = "本季"
    case thisYear = "本年度"
    
    var id: String { rawValue }
}
