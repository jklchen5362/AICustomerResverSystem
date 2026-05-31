//  ReportViewModel.swift
//  AICustomerResverSystem

import Foundation
import SwiftData
import Observation

enum ReportType: String, CaseIterable, Identifiable {
    case customer = "客戶分析報表"
    case revenue = "財務營收統計"
    case treatment = "熱門療程分析"
    case branch = "分店營運效能"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .customer: return "person.2.circle.fill"
        case .revenue: return "dollarsign.circle.fill"
        case .treatment: return "sparkles.tv.fill"
        case .branch: return "building.2.crop.badge.plus"
        }
    }
    
    var description: String {
        switch self {
        case .customer: return "會員增長趨勢、VIP分佈佔比與回訪關懷分析"
        case .revenue: return "月度業績增長、支付工具偏好與客單價分佈"
        case .treatment: return "各項雷射針劑微整銷量、堂數消耗比率排行"
        case .branch: return "各分店據點來客數、營業額佔比與排程飽和度"
        }
    }
}

struct CustomerReportData: Sendable {
    var totalCount: Int = 0
    var vipCount: [String: Int] = [:]
    var growthCount: Int = 0 // added this month
}

struct TreatmentReportData: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
}

@Observable
class ReportViewModel {
    var selectedReportType: ReportType = .customer
    var startDate = Date().startOfMonth
    var endDate = Date().endOfDay
    
    init() {}
    
    func generateCustomerReport(customers: [Customer]) -> CustomerReportData {
        let thisMonthStart = Date().startOfMonth
        
        let growth = customers.filter { $0.createdAt >= thisMonthStart }.count
        
        var vips: [String: Int] = [:]
        for c in customers {
            vips[c.vipLevel.displayName, default: 0] += 1
        }
        
        return CustomerReportData(
            totalCount: customers.count,
            vipCount: vips,
            growthCount: growth
        )
    }
    
    func generateTreatmentReport(packages: [TreatmentPackage]) -> [TreatmentReportData] {
        guard !packages.isEmpty else { return [] }
        
        var counts: [String: Int] = [:]
        for pkg in packages {
            counts[pkg.treatmentName, default: 0] += 1
        }
        
        let total = Double(packages.count)
        
        let sorted = counts.sorted(by: { $0.value > $1.value })
        return sorted.map { 
            TreatmentReportData(
                name: $0.key,
                count: $0.value,
                percentage: Double($0.value) / total
            )
        }
    }
}
