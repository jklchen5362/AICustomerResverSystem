//  TreatmentPackageViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

enum PackageFilterStatus: String, CaseIterable, Identifiable {
    case all = "全部"
    case active = "使用中"
    case expired = "已到期"
    case completed = "已結案"
    
    var id: String { rawValue }
}

@Observable
class TreatmentPackageViewModel {
    var searchText: String = ""
    var filterStatus: PackageFilterStatus = .all
    
    init() {}
    
    func filteredPackages(_ packages: [TreatmentPackage]) -> [TreatmentPackage] {
        var result = packages
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { package in
                package.treatmentName.localizedCaseInsensitiveContains(searchText) ||
                (package.customer?.fullName.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Status filter
        switch filterStatus {
        case .all:
            break
        case .active:
            result = result.filter { package in
                let notExpired = package.expirationDate == nil || package.expirationDate! > Date()
                let remaining = package.remainingSessions > 0
                return notExpired && remaining
            }
        case .expired:
            result = result.filter { package in
                guard let exp = package.expirationDate else { return false }
                return exp <= Date() && package.remainingSessions > 0
            }
        case .completed:
            result = result.filter { $0.remainingSessions == 0 }
        }
        
        // Default sort: Purchase date descending
        result.sort(by: { $0.purchaseDate > $1.purchaseDate })
        
        return result
    }
    
    @MainActor
    func deletePackage(_ package: TreatmentPackage, context: ModelContext) {
        context.delete(package)
        try? context.save()
    }
}
