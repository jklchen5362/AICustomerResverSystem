//  FinancialViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

struct FinancialStats: Sendable {
    var totalRevenue: Double = 0.0
    var avgTransaction: Double = 0.0
    var topPaymentMethod: String = "無"
    var invoiceCount: Int = 0
}

struct BranchRevenue: Identifiable, Sendable {
    let id = UUID()
    let branchName: String
    let revenue: Double
}

struct MonthRevenue: Identifiable, Sendable {
    let id = UUID()
    let monthName: String
    let revenue: Double
}

struct CustomerSpending: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let amount: Double
}

struct ConsultantPerformance: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let amount: Double
    let transactionCount: Int
}

@Observable
class FinancialViewModel {
    var selectedPeriod: FinancialPeriod = .thisMonth
    var startDate: Date = Date().startOfMonth
    var endDate: Date = Date().endOfDay
    
    init() {}
    
    func filterInvoicesByPeriod(_ invoices: [Invoice]) -> [Invoice] {
        let calendar = Calendar.current
        let now = Date()
        
        let start: Date
        let end: Date = now.endOfDay
        
        switch selectedPeriod {
        case .thisMonth:
            start = now.startOfMonth
        case .lastMonth:
            guard let precedingMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
                start = now.startOfMonth
                break
            }
            start = precedingMonth.startOfMonth
            return invoices.filter { $0.purchaseDate >= start && $0.purchaseDate <= precedingMonth.endOfMonth }
        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            start = calendar.date(from: components) ?? now.startOfMonth
        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            start = calendar.date(from: components) ?? now.startOfMonth
        }
        
        return invoices.filter { $0.purchaseDate >= start && $0.purchaseDate <= end }
    }
    
    func calculateStats(invoices: [Invoice]) -> FinancialStats {
        let filtered = filterInvoicesByPeriod(invoices)
        guard !filtered.isEmpty else { return FinancialStats() }
        
        let total = filtered.reduce(0.0) { $0 + $1.amount }
        let avg = total / Double(filtered.count)
        
        // Find top payment method
        var methodsCount: [PaymentMethod: Int] = [:]
        for invoice in filtered {
            methodsCount[invoice.paymentMethod, default: 0] += 1
        }
        let topMethod = methodsCount.max(by: { $0.value < $1.value })?.key ?? .cash
        let topMethodName = topMethod.displayName
        
        return FinancialStats(
            totalRevenue: total,
            avgTransaction: avg,
            topPaymentMethod: topMethodName,
            invoiceCount: filtered.count
        )
    }
    
    func revenueByBranch(invoices: [Invoice], branches: [Branch]) -> [BranchRevenue] {
        let filtered = filterInvoicesByPeriod(invoices)
        var results: [BranchRevenue] = []
        
        for branch in branches {
            let branchInvoices = filtered.filter { $0.branch?.persistentModelID == branch.persistentModelID }
            let branchSum = branchInvoices.reduce(0.0) { $0 + $1.amount }
            results.append(BranchRevenue(branchName: branch.name, revenue: branchSum))
        }
        
        return results.sorted(by: { $0.revenue > $1.revenue })
    }
    
    func revenueByMonth(invoices: [Invoice]) -> [MonthRevenue] {
        var results: [MonthRevenue] = []
        let calendar = Calendar.current
        
        // Fetch revenue for last 6 calendar months
        for i in (0..<6).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let mStart = monthDate.startOfMonth
                let mEnd = monthDate.endOfMonth
                
                let formatter = DateFormatter()
                formatter.dateFormat = "M月"
                let monthName = formatter.string(from: monthDate)
                
                let monthInvoices = invoices.filter { $0.purchaseDate >= mStart && $0.purchaseDate <= mEnd }
                let monthSum = monthInvoices.reduce(0.0) { $0 + $1.amount }
                results.append(MonthRevenue(monthName: monthName, revenue: monthSum))
            }
        }
        
        return results
    }
    
    func topCustomers(invoices: [Invoice]) -> [CustomerSpending] {
        let filtered = filterInvoicesByPeriod(invoices)
        var clientSpending: [String: Double] = [:]
        
        for invoice in filtered {
            if let customer = invoice.customer {
                clientSpending[customer.fullName, default: 0.0] += invoice.amount
            }
        }
        
        let sorted = clientSpending.sorted(by: { $0.value > $1.value }).prefix(5)
        return sorted.map { CustomerSpending(name: $0.key, amount: $0.value) }
    }
    
    func consultantPerformance(invoices: [Invoice]) -> [ConsultantPerformance] {
        let filtered = filterInvoicesByPeriod(invoices)
        var performanceMap: [String: (amount: Double, count: Int)] = [:]
        
        for invoice in filtered {
            let consultant = invoice.salesConsultant.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = consultant.isEmpty ? "未指定經手人" : consultant
            
            let current = performanceMap[name, default: (0.0, 0)]
            performanceMap[name] = (current.amount + invoice.amount, current.count + 1)
        }
        
        let sorted = performanceMap.sorted(by: { $0.value.amount > $1.value.amount })
        return sorted.map { ConsultantPerformance(name: $0.key, amount: $0.value.amount, transactionCount: $0.value.count) }
    }
}
