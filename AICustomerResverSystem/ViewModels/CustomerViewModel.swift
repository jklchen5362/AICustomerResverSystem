//  CustomerViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

enum CustomerSortOrder: String, CaseIterable, Identifiable {
    case name = "姓名"
    case recentVisit = "最近來訪"
    case totalSpent = "消費總額"
    case vipLevel = "VIP等級"
    
    var id: String { rawValue }
}

@Observable
class CustomerViewModel {
    var searchText: String = ""
    var selectedVIPFilter: VIPLevel? = nil
    var sortOrder: CustomerSortOrder = .name
    
    init() {}
    
    func filteredCustomers(_ customers: [Customer]) -> [Customer] {
        var result = customers
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { customer in
                customer.fullName.localizedCaseInsensitiveContains(searchText) ||
                customer.phone.localizedCaseInsensitiveContains(searchText) ||
                customer.email.localizedCaseInsensitiveContains(searchText) ||
                customer.lineID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // VIP level filter
        if let vip = selectedVIPFilter {
            result = result.filter { $0.vipLevel == vip }
        }
        
        // Sorting
        switch sortOrder {
        case .name:
            result.sort(by: { $0.fullName.localizedCompare($1.fullName) == .orderedAscending })
        case .recentVisit:
            // Sort by most recent appointment or createdAt
            result.sort(by: {
                let d1 = $0.appointments.compactMap({ $0.appointmentDate }).max() ?? $0.createdAt
                let d2 = $1.appointments.compactMap({ $0.appointmentDate }).max() ?? $1.createdAt
                return d1 > d2
            })
        case .totalSpent:
            result.sort(by: {
                let sum1 = $0.totalSpent
                let sum2 = $1.totalSpent
                return sum1 > sum2
            })
        case .vipLevel:
            // Order: Diamond, Platinum, Gold, Silver, Bronze, Regular
            let weight: (VIPLevel) -> Int = { level in
                switch level {
                case .diamond: return 5
                case .platinum: return 4
                case .gold: return 3
                case .silver: return 2
                case .bronze: return 1
                case .regular: return 0
                }
            }
            result.sort(by: { weight($0.vipLevel) > weight($1.vipLevel) })
        }
        
        return result
    }
    
    @MainActor
    func deleteCustomer(_ customer: Customer, context: ModelContext) {
        context.delete(customer)
        try? context.save()
    }
    
    @MainActor
    func saveCustomer(_ customer: Customer, context: ModelContext) {
        context.insert(customer)
        try? context.save()
    }
}
